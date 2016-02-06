//
//  GameViewController.swift
//  Magic
//
//  Created by mengyun on 16/1/30.
//  Copyright © 2016年 mengyun. All rights reserved.
//

import GLKit
import OpenGLES

//let shaderES2=1    //可编程着色器开关,＝=1则打开

func BUFFER_OFFSET(i: Int) -> UnsafePointer<Void> {
    let p: UnsafePointer<Void> = nil
    return p.advancedBy(i)
}

let UNIFORM_MODELVIEWPROJECTION_MATRIX = 0
let UNIFORM_NORMAL_MATRIX = 1
let UNIFORM_TEXTURE=2
var uniforms = [GLint](count: 3, repeatedValue: 0)

class GameViewController: GLKViewController {
    
    var program: GLuint = 0
    
    var modelViewProjectionMatrix:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix: GLKMatrix3 = GLKMatrix3Identity
    var rotation: Float = 0.0
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0
    
    var context: EAGLContext? = nil
    var effect: GLKBaseEffect? = nil
    
    var cube: CubeData!
    var m_BlockData:BlockData!
    
    var move_flag:Bool=true
    var point1:CGPoint!//手指屏幕坐标
    var point2:CGPoint!
    
    var startVec3:[Float]=[Float](count: 3, repeatedValue: 0.0)//轨迹球坐标
    var endVec3:[Float]=[Float](count: 3, repeatedValue: 0.0)
    var rotQuaternion:[Float]=[Float](count: 4, repeatedValue: 0.0)//旋转四元数
    var rotMat:GLKMatrix4=GLKMatrix4Identity //旋转矩阵
    var tmpMat:GLKMatrix4=GLKMatrix4Identity //上次旋转的矩阵
    //var pickBlockData:[[Int]]=[[Int]](count: 2, repeatedValue: [Int](count: 3, repeatedValue: 0))
    
    var currentPickPixel:[GLubyte]=[GLubyte](count: 3, repeatedValue: 0)   //当前pick的颜色数据
    var pickPixels:[[GLubyte]]=[[GLubyte]](count: 2, repeatedValue: [GLubyte](count: 3, repeatedValue: 0))  //pick方块的颜色数据
    var pickFlags=0  //0表示选中方块，10表示选中一个
    
    var timer=0   //帧计数

    deinit {
        self.tearDownGL()
        
        if EAGLContext.currentContext() === self.context {
            EAGLContext.setCurrentContext(nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.context = EAGLContext(API: .OpenGLES2)
        if !(self.context != nil) {
            //print("Failed to create ES context")
        }
        
        let view = self.view as! GLKView
        view.context = self.context!
        view.drawableDepthFormat = .Format24
        
        self.setupGL()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if self.isViewLoaded() && (self.view.window != nil) {
            self.view = nil
            
            self.tearDownGL()
            
            if EAGLContext.currentContext() === self.context {
                EAGLContext.setCurrentContext(nil)
            }
            self.context = nil
        }
    }
    
    func setupGL() {
        EAGLContext.setCurrentContext(self.context)
        self.loadShaders()
        glEnable(UInt32(GL_DEPTH_TEST))
        glEnable(UInt32(GL_SMOOTH))
        glActiveTexture(UInt32(GL_TEXTURE0))
        cube=CubeData()
        cube.CubeSetupData()
        m_BlockData=BlockData()
        m_BlockData.initBlockData()
        m_BlockData.initTextures()
    }
    
    func tearDownGL() {
        EAGLContext.setCurrentContext(self.context)
        
        glDeleteBuffers(1, &vertexBuffer)
        glDeleteVertexArraysOES(1, &vertexArray)
        
        self.effect = nil
        
        if program != 0 {
            glDeleteProgram(program)
            program = 0
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        point1=(touches as NSSet).anyObject()!.locationInView(self.view)
        //print(point1)
        move_flag=false
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        point2=(touches as NSSet).anyObject()!.locationInView(self.view)
        if (point2.x-point1.x)*(point2.x-point1.x)>0-(point2.y-point1.y)*(point2.y-point1.y){
            if move_flag{
                startVec3=mapToSphere(point2)
                endVec3=mapToSphere(point1)
                getQuaternion()
                getRotationMatrix()
            }
            move_flag=true
        }
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        tmpMat=rotMat
        if(move_flag == false){
            for i in 0...1{
                if currentPickPixel[0]>4||currentPickPixel[0]<1||currentPickPixel[0]==pickPixels[i][0]&&currentPickPixel[1]==pickPixels[i][1]&&currentPickPixel[2]==pickPixels[i][2]{
                    pickPixels[0][0]=0
                    pickPixels[0][1]=0
                    pickPixels[0][2]=0
                    pickPixels[1][0]=0
                    pickPixels[1][1]=0
                    pickPixels[1][2]=0
                    pickFlags=0
                    return
                }
            }
            if pickFlags==0{
                pickPixels[0][0]=currentPickPixel[0]
                pickPixels[0][1]=currentPickPixel[1]
                pickPixels[0][2]=currentPickPixel[2]
                pickFlags=10
            }
            else if pickFlags==10{
                pickPixels[1][0]=currentPickPixel[0]
                pickPixels[1][1]=currentPickPixel[1]
                pickPixels[1][2]=currentPickPixel[2]
                var ii:[Int]=[Int(pickPixels[0][0]),Int(pickPixels[1][0])]
                var jj:[Int]=[Int(pickPixels[0][1]),Int(pickPixels[1][1])]
                var kk:[Int]=[Int(pickPixels[0][2]),Int(pickPixels[1][2])]
                if(m_BlockData.trueTexture[ii[0]][jj[0]][kk[0]]==m_BlockData.trueTexture[ii[1]][jj[1]][kk[1]]){
                    if m_BlockData.falseBFS(ii[0],y1: jj[0],z1: kk[0],x2: ii[1],y2: jj[1],z2: kk[1]){
                        m_BlockData.hidden[ii[0]][jj[0]][kk[0]]=true
                        m_BlockData.hidden[ii[1]][jj[1]][kk[1]]=true
                    }
                }
                pickPixels[0][0]=0
                pickPixels[0][1]=0
                pickPixels[0][2]=0
                pickPixels[1][0]=0
                pickPixels[1][1]=0
                pickPixels[1][2]=0
                pickFlags=0
            }
        }
    }

    //获得pick点的颜色数据
    func pickColour(point:CGPoint){
        let viewport=UnsafeMutablePointer<GLint>.alloc(4*sizeof(GLint))
        glGetIntegerv(UInt32(GL_VIEWPORT), viewport)
        let pixel=UnsafeMutablePointer<GLubyte>.alloc(4*sizeof(GLubyte))
        let x:GLint=2*GLint(point.x)
        let y:GLint=GLint(viewport[3])-2*GLint(point.y)
        glReadPixels(x,y,1,1,GLenum(GL_RGBA),GLenum(GL_UNSIGNED_BYTE),pixel)
        ////print("viewport............",viewport[0],viewport[1],viewport[2],viewport[3])
        ////print("pickColour.....",pixel[0],pixel[1],pixel[2],pixel[3])
        for i in 0...2{
            currentPickPixel[i]=pixel[i]
        }
    }
    
    //只做pick时调用
    func pickDraw(){
        let modeMatrix=modelViewProjectionMatrix
        let dis:GLfloat=0.1
        for i in 1...4{
            for j in 1...4{
                for k in 1...4{
                    if m_BlockData.hidden[i][j][k]{
                        continue
                    }
                    glBindTexture(GLenum(GL_TEXTURE_2D),m_BlockData.pickTexture[i][j][k])
                    ////print("pickDraw.....",m_BlockData.pickTexture[i][j][k])
                    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
                    
                    let tempModeviewMatrix=modelViewProjectionMatrix
                    let tempMatrix = GLKMatrix4MakeTranslation((GLfloat)(i-1)+dis*GLfloat(i-1), (GLfloat)(j-1)+dis*GLfloat(j-1), (GLfloat)(k-1)+dis*GLfloat(k-1))
                    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix,tempMatrix)
                    withUnsafePointer(&modelViewProjectionMatrix, {
                        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, UnsafePointer($0))
                    })
                    cube.CubeDraw()
                    modelViewProjectionMatrix = tempModeviewMatrix
                }
            }
        }
        pickColour(point1)
        modelViewProjectionMatrix = modeMatrix;
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
    }
    
    //CFPoint映射到轨迹球上
    func mapToSphere(point: CGPoint)->[Float]{
        let adjustWidth:CGFloat=1.0/((375-1.0)*0.5)
        let adjustHeight:CGFloat=1.0/((667-1.0)*0.5)
        var tmpPoint:CGPoint=CGPoint()
        tmpPoint.x=(point.x*adjustWidth)-1.0
        tmpPoint.y=1.0-(point.y*adjustHeight)
        let length=(tmpPoint.x*tmpPoint.x)+(tmpPoint.y*tmpPoint.y)
        var tmpVec3:[Float]=[Float](count: 3, repeatedValue: 0.0)
        if length>1.0{
            tmpVec3[0]=Float(tmpPoint.x/sqrt(length))
            tmpVec3[1]=Float(tmpPoint.y/sqrt(length))
            tmpVec3[2]=0.0
        }
        else{
            tmpVec3[0]=Float(tmpPoint.x)
            tmpVec3[1]=Float(tmpPoint.y)
            tmpVec3[2]=Float(sqrt(1.0-length))
        }
        return tmpVec3
    }
    
    //求得轨迹球旋转四元数
    func getQuaternion(){
        rotQuaternion[0]=(startVec3[1]*endVec3[2])-(startVec3[2]*endVec3[1])
        rotQuaternion[1]=(startVec3[2]*endVec3[0])-(startVec3[0]*endVec3[2])
        rotQuaternion[2]=(startVec3[0]*endVec3[1])-(startVec3[1]*endVec3[0])
        var length=rotQuaternion[0]*rotQuaternion[0]+rotQuaternion[1]*rotQuaternion[1]
        length=length+rotQuaternion[2]*rotQuaternion[2]
        if length>0.0{
            rotQuaternion[3]=(startVec3[0]*endVec3[0]) + (startVec3[1] * endVec3[1]) + (startVec3[2] * endVec3[2])
        }
        else{
            rotQuaternion[0]=0.0
            rotQuaternion[1]=0.0
            rotQuaternion[2]=0.0
            rotQuaternion[3]=0.0
        }
    }

    //求得轨迹球旋转矩阵
    func getRotationMatrix(){
        let x=rotQuaternion[0];
        let y=rotQuaternion[1];
        let z=rotQuaternion[2];
        let w=rotQuaternion[3];
        let x2 = x * x;
        let y2 = y * y;
        let z2 = z * z;
        let xy = x * y;
        let xz = x * z;
        let yz = y * z;
        let wx = w * x;
        let wy = w * y;
        let wz = w * z;
        
        let m00:Float=1.0-2.0*(y2+z2)
        let m01:Float=2.0*(xy-wz)
        let m02:Float=2.0*(xz+wy)
        let m03:Float=0.0;
        let m10:Float=2.0*(xy+wz);
        let m11:Float=1.0-2.0*(x2+z2)
        let m12:Float=2.0*(yz-wx)
        let m13:Float=0.0
        let m20:Float=2.0*(xz-wy)
        let m21:Float=2.0*(yz+wx)
        let m22:Float=1.0-2.0*(x2 + y2)
        let m23:Float=0.0
        let m30:Float=0.0
        let m31:Float=0.0
        let m32:Float=0.0
        let m33:Float=1.0
        rotMat=GLKMatrix4Make(m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33)
        rotMat=GLKMatrix4Multiply(rotMat,tmpMat);
    }
    
    // MARK: - GLKView and GLKViewController delegate methods
    
    func update() {
        let aspect = fabsf(Float(self.view.bounds.size.width / self.view.bounds.size.height))
        let projectionMatrix=GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0), aspect, 0.1, 100.0);
        
        var modelViewMatrix:GLKMatrix4=GLKMatrix4MakeTranslation(0.0, 0.0, -14.0)
        modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix,rotMat);
        normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), nil);
        modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    }
    
    override func glkView(view: GLKView, drawInRect rect: CGRect) {
        //glClearColor(0.65, 0.65, 0.65, 1.0)
        glClearColor(0.05, 0.05, 0.05, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        glBindVertexArrayOES(vertexArray)
        
        // Render the object again with ES2
        glUseProgram(program)
        
        cube.CubeBindVertexArray()
        
        let tempMatrix=GLKMatrix4MakeTranslation(-1.5, -1.5, -1.5)
        modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix,tempMatrix)
        withUnsafePointer(&modelViewProjectionMatrix, {
            glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, UnsafePointer($0))
        })
        
        withUnsafePointer(&normalMatrix, {
            glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, UnsafePointer($0))
        })
        if(move_flag == false){
            pickDraw()
            ////print("/...................pickDraw")
        }
        timer+=1
        let dis:GLfloat=0.1
        for i in 1...4{
            for j in 1...4{
                for k in 1...4{
                    if m_BlockData.hidden[i][j][k]{
                        continue
                    }
                    if pickFlags==10&&timer%18==0{
                        if Int(pickPixels[0][0])==i&&Int(pickPixels[0][1])==j&&Int(pickPixels[0][2])==k{
                            continue
                        }
                    }
                    ////print("/...................CubeDraw")
                    glBindTexture(GLenum(GL_TEXTURE_2D),m_BlockData.trueTexture[i][j][k])
//                    //print(m_BlockData.trueTexture[i][j][k],".............")
                    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
                    
                    let tempModeviewMatrix=modelViewProjectionMatrix
                    let tempMatrix = GLKMatrix4MakeTranslation((GLfloat)(i-1)+dis*GLfloat(i-1), (GLfloat)(j-1)+dis*GLfloat(j-1), (GLfloat)(k-1)+dis*GLfloat(k-1))
                    modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewProjectionMatrix,tempMatrix)
                    withUnsafePointer(&modelViewProjectionMatrix, {
                        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, UnsafePointer($0))
                    })
                    cube.CubeDraw()
                    modelViewProjectionMatrix = tempModeviewMatrix
                }
            }
        }
    }
    
    // MARK: -  OpenGL ES 2 shader compilation
    //loadShaders()步骤：
    //1.创建程序。
    //2.创建并编译顶点着色器和片段着色器。
    //3.把 顶点着色器和片段着色器 与 程序连接起来。
    //4.设置 顶点着色器和片段着色器 的输入参数。
    //5.链接程序。
    //6.获取 uniform 指针。
    //注意：这步只能在5成功后才能调用，在linkProgrom前，uniform位置是不确定的。
    //7.断开 顶点着色器和片段着色器 ，并释放它们。
    //注意：程序并没释放。
    //
    //第4步是会变化的部分，第6步为可选。
    func loadShaders() -> Bool {
        var vertShader: GLuint = 0
        var fragShader: GLuint = 0
        var vertShaderPathname: String
        var fragShaderPathname: String
        
        //创建程序.
        program = glCreateProgram()
        
        //创建并编译顶点着色器.
        vertShaderPathname = NSBundle.mainBundle().pathForResource("Shader", ofType: "vsh")!
        if self.compileShader(&vertShader, type: GLenum(GL_VERTEX_SHADER), file: vertShaderPathname) == false {
            //print("Failed to compile vertex shader")
            return false
        }
        //创建并编译片段着色器.
        fragShaderPathname = NSBundle.mainBundle().pathForResource("Shader", ofType: "fsh")!
        if !self.compileShader(&fragShader, type: GLenum(GL_FRAGMENT_SHADER), file: fragShaderPathname) {
            //print("Failed to compile fragment shader")
            return false
        }
        
        //把顶点着色器与程序连接起来.
        glAttachShader(program, vertShader)
        //把片段着色器与程序连接起来.
        glAttachShader(program, fragShader)
        
        //设置 顶点着色器和片段着色器 的输入参数。
        //"position"和"normal"与着色器代码Shader.vsh里面的2个attribute对应，
        //分别与setupGL加载的顶点数组里面的顶点和法线数据对应起来。
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.Position.rawValue), "position")
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.Normal.rawValue), "normal")
        
        //链接程序.
        if !self.linkProgram(program) {
            //print("Failed to link program: \(program)")
            
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
        
        //获取 uniform 指针.
        uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(program, "modelViewProjectionMatrix")
        uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(program, "normalMatrix")
        
        //释放着色器
        if vertShader != 0 {
            glDetachShader(program, vertShader)
            glDeleteShader(vertShader)
        }
        if fragShader != 0 {
            glDetachShader(program, fragShader)
            glDeleteShader(fragShader)
        }
        
        return true
    }
    
    
    func compileShader(inout shader: GLuint, type: GLenum, file: String) -> Bool {
        var status: GLint = 0
        var source: UnsafePointer<Int8>
        do {
            source = try NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding).UTF8String
        } catch {
            //print("Failed to load vertex shader")
            return false
        }
        var castSource = UnsafePointer<GLchar>(source)
        
        shader = glCreateShader(type)
        glShaderSource(shader, 1, &castSource, nil)
        glCompileShader(shader)
        
        //#if defined(DEBUG)
        //        var logLength: GLint = 0
        //        glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        //        if logLength > 0 {
        //            var log = UnsafeMutablePointer<GLchar>(malloc(Int(logLength)))
        //            glGetShaderInfoLog(shader, logLength, &logLength, log)
        //            NSLog("Shader compile log: \n%s", log)
        //            free(log)
        //        }
        //#endif
        
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
        if status == 0 {
            glDeleteShader(shader)
            return false
        }
        return true
    }
    
    func linkProgram(prog: GLuint) -> Bool {
        var status: GLint = 0
        glLinkProgram(prog)
        
        //#if defined(DEBUG)
        //        var logLength: GLint = 0
        //        glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        //        if logLength > 0 {
        //            var log = UnsafeMutablePointer<GLchar>(malloc(Int(logLength)))
        //            glGetShaderInfoLog(shader, logLength, &logLength, log)
        //            NSLog("Shader compile log: \n%s", log)
        //            free(log)
        //        }
        //#endif
        
        glGetProgramiv(prog, GLenum(GL_LINK_STATUS), &status)
        if status == 0 {
            return false
        }
        
        return true
    }
    
    func validateProgram(prog: GLuint) -> Bool {
        var logLength: GLsizei = 0
        var status: GLint = 0
        
        glValidateProgram(prog)
        glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            var log: [GLchar] = [GLchar](count: Int(logLength), repeatedValue: 0)
            glGetProgramInfoLog(prog, logLength, &logLength, &log)
            //print("Program validate log: \n\(log)")
        }
        
        glGetProgramiv(prog, GLenum(GL_VALIDATE_STATUS), &status)
        var returnVal = true
        if status == 0 {
            returnVal = false
        }
        return returnVal
    }
}