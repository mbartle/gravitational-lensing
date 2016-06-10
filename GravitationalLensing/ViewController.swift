//
//  ViewController.swift
//  GravitationalLensing
//
//  Created by Mason Bartle on 6/1/16.
//  Copyright © 2016 Mason Bartle. All rights reserved.
//
//  Heavily influenced by open source GLCameraRipple code

import UIKit
import AVFoundation
import GLKit
import OpenGLES

enum Attribute: GLuint {
    case ATTRIB_VERTEX
    case ATTRIB_TEXCOORD
    case NUM_ATTRIBUTES
}

enum Uniform: GLint {
    case UNIFORM_Y
    case UNIFORM_UV
    case NUM_UNIFORMS
}

class ViewController: GLKViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: Properties
    var textureHeight: size_t?
    var textureWidth: size_t?
    var screenHeight: CGFloat?
    var screenWidth: CGFloat?
    
    // This controls the ending mesh size, mesh width = screenWidth / meshFactor
    // Chosen based on screen resolution and device size
    let meshFactor = 8
    
    // AV variables
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var facingCamera: AVCaptureDevice?
    
    // OpenGLES variables
    var context: EAGLContext?
    var program = glCreateProgram()
    var uniforms = [GLint](count: Int(Uniform.NUM_UNIFORMS.rawValue), repeatedValue: 0)
    
    var gravModel: GravModel?
    @IBOutlet weak var lensingObject: LensingObject!
    
    
    // MARK: Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set up EAGLContext (state information, commands, and resources necessary for OpenGLES
        context = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)!
        self.preferredFramesPerSecond = 60;
        
        // Get screen size to pass to model class
        screenWidth = UIScreen.mainScreen().bounds.size.width
        screenHeight = UIScreen.mainScreen().bounds.size.height
        view.contentScaleFactor = UIScreen.mainScreen().scale
        
        self.setupVideoCapture()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didDropSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        if gravModel == nil || width != textureWidth || height != textureHeight {
            textureWidth = width; textureHeight = height
            gravModel = GravModel(width: Int(screenWidth!), height: Int(screenHeight!), factor: meshFactor, texWidth: textureWidth!, texHeight: textureHeight!)
        }
    }
    
    // MARK: Camera Initialization
    
    func setupVideoCapture() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        facingCamera = AVCaptureDevice.defaultDeviceWithMediaType("AVMediaTypeVideo")
        
        // set up camera input
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: facingCamera))
        } catch {
            print ("Error creating captureSession")
        }
        
        // set up camera output
        let videoOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(videoOutput)
        // must call self as delegate, and self must implement delegate behavior
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())
        videoOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(videoOutput)
        
        // commit changes and begin sending data to output
        captureSession.commitConfiguration()
        captureSession.startRunning()
        
        // TODO: Handle case where there is no camera
        if facingCamera == nil {
            
        }
    }
    
    // MARK: Graphics Library Manipulation
    
    func setupGL() {
        EAGLContext.setCurrentContext(context)
        self.loadShaders()
        glUseProgram(program)
        glUniform1i(uniforms[Uniform.UNIFORM_Y.hashValue], 0)
        glUniform1i(uniforms[Int(Uniform.UNIFORM_UV.hashValue)], 1)
    }
    
    func loadShaders() -> Bool {
        var vertShader = GLuint()
        var fragShader = GLuint()
        
        // Create and compile vertex shader
        let vertShaderPathname = NSBundle.mainBundle().pathForResource("Shader", ofType: "vsh")!
        if !self.compileShader(&vertShader, type: UInt32(GL_VERTEX_SHADER), file: vertShaderPathname) {
            NSLog("Failed to compile vertex shader")
            return false
        }
        
        // Create and compile fragment shader
        let fragShaderPathname = NSBundle.mainBundle().pathForResource("Shader", ofType: "fsh")!
        if !self.compileShader(&fragShader, type: UInt32(GL_FRAGMENT_SHADER), file: fragShaderPathname) {
            NSLog("Failed to compile fragment shader")
            return false
        }
        
        // Attach shaders to program
        glAttachShader(program, vertShader)
        glAttachShader(program, fragShader)
        
        // Bind attribute locations before linking
        glBindAttribLocation(program, Attribute.ATTRIB_VERTEX.rawValue, "position")
        glBindAttribLocation(program, Attribute.ATTRIB_TEXCOORD.rawValue, "texCoord")
        
        // Link program
        if !self.linkProgram(program) {
            NSLog("Failed to link program: %d", program)
            if vertShader != 0 {
                glDeleteShader(vertShader)
                vertShader = 0
            }
            if fragShader != 0 {
                glDeleteShader(fragShader)
                fragShader = 0
            }
            if program != 0 {
                glDeleteProgram(program)
                program = 0
            }
            return false
        }
        
        // Get uniform locations
        uniforms[Int(Uniform.UNIFORM_Y.rawValue)] = glGetUniformLocation(program, "SamplerY")
        uniforms[Int(Uniform.UNIFORM_UV.rawValue)] = glGetUniformLocation(program, "SamplerUV")
        
        //Release vertex and fragment shaders
        if (vertShader != 0) {
            glDetachShader(program, vertShader)
            glDeleteShader(vertShader)
        }
        if (fragShader != 0) {
            glDetachShader(program, fragShader)
            glDeleteShader(fragShader)
        }
        
        return true
    }
    
    func compileShader(inout shader: GLuint, type: GLenum, file: NSString) -> Bool {
        var source: UnsafePointer<GLchar>
        
        // Set source to contents of file
        do {
            source = try NSString(contentsOfFile: file as String, encoding: NSUTF8StringEncoding).UTF8String
        } catch {
            NSLog("Failed to load vertex shader")
            return false
        }
        
        // create a shader from type
        shader = glCreateShader(type)
        // first argument shader, second num of elements in last two arguments, third an array of pointers to source,
        // fourth an array of string lengths corresponding to strings in source, nil assumes those strings are null-terminated
        // this method is an OpenGL method that sets the source code in the shader to the variable source
        glShaderSource(shader, 1, &source, nil)
        glCompileShader(shader)
        
        // Must initialize status variable before checking status
        var status = GLint()
        
        // returns into the inout variable status the status of compilation, if 0, compilation was not successful
        glGetShaderiv(shader, UInt32(GL_COMPILE_STATUS), &status)
        if (status == 0) {
            glDeleteShader(shader)
            return false
        }
        return true
    }
    
    func linkProgram(prog: GLuint) -> Bool {
        glLinkProgram(prog)
        
        // Must initialize status variable before checking status
        var status = GLint()
        
        glGetProgramiv(prog, UInt32(GL_LINK_STATUS), &status)
        if status == 0 {
            return false
        }
        
        return true
    }
    
}

