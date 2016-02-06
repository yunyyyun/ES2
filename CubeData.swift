//
//  Cube.swift
//  ES2
//
//  Created by mengyun on 16/2/3.
//  Copyright © 2016年 mengyun. All rights reserved.
//

import GLKit
import OpenGLES

class CubeData: NSObject {
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0

    func CubeSetupData(){
        glGenVertexArraysOES(1, &vertexArray)
        glBindVertexArrayOES(vertexArray)
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(sizeof(GLfloat) * CubeVertexData.count), &CubeVertexData, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 20, BUFFER_OFFSET(0))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Normal.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Normal.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 20, BUFFER_OFFSET(12))
        
    }

    func CubeBindVertexArray() {
        glBindVertexArrayOES(vertexArray);
    }
            
    func CubeDraw(){
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(CubeVertexData.count/5));
    }
    
}

