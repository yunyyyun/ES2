//
//  BlockData.swift
//  ES2
//
//  Created by mengyun on 16/2/4.
//  Copyright © 2016年 mengyun. All rights reserved.
//

import GLKit
import OpenGLES

let textureNum=24
let texturefileName: [String]=[
    "face1.png",   "facex1.png", "face2.png",  "facex2.png", "face3.png", "facex3.png"
    ,"face4.png",   "facex4.png","face5.png",  "facex5.png", "face6.png", "facex6.png"
    ,"face7.png",   "facex7.png" ,"face8.png",  "facex8.png", "face9.png", "facex9.png"
    ,"face10.png",  "facex10.png","face11.png", "facex11.png","face12.png","facex12.png"
]

class BlockData {

    var textureArray = [GLuint](count: textureNum, repeatedValue:1)  //纹理数组
    var pickTexture = [[[GLuint]]](count: 6, repeatedValue:[[GLuint]](count: 6, repeatedValue:
        [GLuint](count: 6, repeatedValue:0)))   //隐藏纹理，用作pick
    var trueTexture = [[[GLuint]]](count: 6, repeatedValue:[[GLuint]](count: 6, repeatedValue:
        [GLuint](count: 6, repeatedValue:0)))  //方块真实显示的纹理
    //var hidden:[[[Bool]]]!          //方块是否隐藏
    var hidden = [[[Bool]]](count: 6, repeatedValue:[[Bool]](count: 6, repeatedValue:
        [Bool](count: 6, repeatedValue:false)))
    
    
    
    func initBlockData(){
        for i in 0...5{
            for j in 0...5{
                for k in 0...5{
                    hidden[i][j][k]=(i==0||i==5||j==0||j==5||k==0||k==5)
                }
            }
        }
    }
    
    func initTextures(){
        for i in 0...textureNum-1 {
            textureArray[i] = loadTexture(texturefileName[i]) //全部纹理数组
        }
        
        for i in 1...4{
            for j in 1...4{
                for k in 1...4{
                    pickTexture[i][j][k]=loadPickTexture(i, jj: j, kk: k) //pick的纹理，用作后面pick方块
                }
            }
        }
        
        for i in 1...4{
            for j in 1...4{
                for k in 1...4{
                    var temp:Int = Int(arc4random())%64
                    if temp>=48{
                        temp-=48
                    }
                    if temp>=24{
                        temp-=24
                    }
                    trueTexture[i][j][k]=textureArray[temp]  //真实显示的纹理
                }
            }
        }
    }
    
    func loadTexture(fileName: String)->GLuint{
        let textureImage=UIImage(named: fileName)?.CGImage
        if textureImage==nil {
            print("waring:Failed to load image", fileName)
        }
        let width=CGImageGetWidth(textureImage)
        let height=CGImageGetHeight(textureImage)
        let textureData=calloc(width*height*4, sizeof(GLubyte))
        //let bithiddenInfo = CGBithiddenInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        let textureContext=CGBitmapContextCreate(textureData, width, height, 8, width*4, CGImageGetColorSpace(textureImage), UInt32(1))//todo
        
        CGContextDrawImage(textureContext, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), textureImage)
        
        var textureName:GLuint=0
        glGenTextures(1, &textureName)
        glBindTexture(UInt32(GL_TEXTURE_2D), textureName)
        glTexParameteri(UInt32(GL_TEXTURE_2D), UInt32(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        glTexImage2D(UInt32(GL_TEXTURE_2D), 0, GLint(GL_RGBA), GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), textureData)
        return textureName
    }
    
    func loadPickTexture(ii:Int,jj:Int,kk:Int)->GLuint{
        let textureImage=UIImage(named: texturefileName[5])?.CGImage
        if textureImage==nil {
            print("waring:Failed to load image", texturefileName[0])
        }
        let width=CGImageGetWidth(textureImage)
        let height=CGImageGetHeight(textureImage)
        //let textureData=calloc(width*height*4, sizeof(GLubyte))
        let textureData=UnsafeMutablePointer<GLubyte>.alloc(width*height*4*sizeof(GLubyte))
        //let bithiddenInfo = CGBithiddenInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        let textureContext=CGBitmapContextCreate(textureData, width, height, 8, width*4, CGImageGetColorSpace(textureImage), UInt32(1))//todo
        
        CGContextDrawImage(textureContext, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), textureImage)
        //print("textureData.............",textureData[0],textureData[120*120],textureData[1000],textureData[128*128*4-1])
        
        var textureName:GLuint=0
        glGenTextures(1, &textureName)
        glBindTexture(UInt32(GL_TEXTURE_2D), textureName)
        glTexParameteri(UInt32(GL_TEXTURE_2D), UInt32(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        
        let mWidth = Int(width)
        let mHeight = Int(height)
        for i in 0...mWidth-1{
            for j in 0...mHeight-1{
                textureData[(i+j*mWidth)*4+0] = GLubyte(ii);
                textureData[(i+j*mWidth)*4+1] = GLubyte(jj);
                textureData[(i+j*mWidth)*4+2] = GLubyte(kk);
                textureData[(i+j*mWidth)*4+3] = GLubyte(255);
            }
        }
        //print("textureData.............",mWidth,mHeight,textureData[0],textureData[120*120],textureData[1000],textureData[128*128*4-1])
        glTexImage2D(UInt32(GL_TEXTURE_2D), 0, GLint(GL_RGBA), GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), textureData)
        return textureName
    }
    
    //计算是否能消除
    func falseBFS(x1:Int,y1:Int,z1:Int,x2:Int,y2:Int,z2:Int)->Bool{
        if ((x1==x2&&y1==y2)||(z1==z2&&y1==y2)||(x1==x2&&z1==z2)) {
            return lineTest(x1, y1: y1, z1: z1, x2: x2, y2: y2, z2: z2);
        }
        if (z1==z2){
            if (hidden[x1][y2][z2]==true&&lineTest(x1, y1: y1, z1: z1, x2: x1, y2: y2, z2: z2)&&lineTest(x2, y1: y2, z1: z2, x2: x1, y2: y2, z2: z2)) {
                return true;
            }
            if (hidden[x2][y1][z2]==true&&lineTest(x1, y1: y1, z1: z1, x2: x2, y2: y1, z2: z2)&&lineTest(x2, y1: y2, z1: z2, x2: x2, y2: y1, z2: z2)) {
                return true;
            }
            return false;
        }
        if (x1==x2){
            if (hidden[x1][y1][z2]==true&&lineTest(x1, y1: y1, z1: z1, x2: x1, y2: y1, z2: z2)&&lineTest(x2, y1: y2, z1: z2, x2: x1, y2: y1, z2: z2)) {
                return true;
            }
            if (hidden[x2][y2][z1]==true&&lineTest(x1, y1: y1, z1: z1, x2: x2, y2: y2, z2: z1)&&lineTest(x2, y1: y2, z1: z2, x2: x2, y2: y2, z2: z1)) {
                return true;
            }
            return false;
        }
        if (y1==y2){
            if (hidden[x1][y2][z2]==true&&lineTest(x1, y1: y1, z1: z1, x2: x1, y2: y2, z2: z2)&&lineTest(x2, y1: y2, z1: z2, x2: x1, y2: y2, z2: z2)) {
                return true;
            }
            if (hidden[x2][y1][z1]==true&&lineTest(x1, y1: y1, z1: z1, x2: x2, y2: y1, z2: z1)&&lineTest(x2, y1: y2, z1: z2, x2: x2, y2: y1, z2: z1)) {
                return true;
            }
            return false;
        }
        if (falseBFS(x1, y1: y1, z1: z2, x2: x2, y2: y2, z2: z2)&&hidden[x1][y1][z2]==true)||(falseBFS(x2, y1: y1, z1: z1, x2: x2, y2: y2, z2: z2)&&hidden[x2][y1][z1]==true)||(falseBFS(x1, y1: y2, z1: z1, x2: x2, y2: y2, z2: z2)&&hidden[x1][y2][z1]==true){
            return true
        }
        return false;
    }
    
    //共线测试
    func lineTest(var x1:Int,var y1:Int,var z1:Int,var x2:Int,var y2:Int,var z2:Int)->Bool{
        if (x1==x2&&y1==y2){
            if (z1>z2){
                z1=z1+z2;
                z2=z1-z2;
                z1=z1-z2;
            }
            if (z1+1==z2) {
                return true
            }
            else{
                for z in z1+1...z2-1{
                    if (hidden[x1][y1][z] == false) {
                        return false;
                    }
                }
                return true;
            }
        }
        if (x1==x2&&z1==z2){
            if (y1>y2){
                y1=y1+y2;
                y2=y1-y2;
                y1=y1-y2;
            }
            if (y1+1==y2) {
                return true;
            }
            else{
                for y in y1+1...y2-1{
                    if (hidden[x1][y][z1] == false) {
                        return false;
                    }
                    return true;
                }
            }
        }
        if (z1==z2&&y1==y2){
            if (x1>x2){
                x1=x1+x2;
                x2=x1-x2;
                x1=x1-x2;
            }
            if (x1+1==x2) {
                return true;
            }
            else{
                for x in x1+1...x2-1{
                    if (hidden[x][y1][z1] == false) {
                        return false;
                    }
                    return true;
                }
            }
        }
        return false;
    }
}













