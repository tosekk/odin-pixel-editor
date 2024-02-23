package main

import "core:fmt"
import la "core:math/linalg"

import rl "vendor:raylib"


// CONSTANTS
APP_TITLE: cstring = "Pixel Editor"
SCREEN_WIDTH: f32 = 800
SCREEN_HEIGHT: f32 = 500
SCREEN_BG_COLOR: rl.Color = { 109, 104, 117, 255 }
FOREGROUND_COLOR: rl.Color = { 0, 0, 0, 255 }
BACKGROUND_COLOR: rl.Color = { 255, 255, 255, 255 }
CANVAS_COLOR: rl.Color = { 255, 255, 255, 255 }

// TO-DO
/*
    1. Snap pixels
    2. UI
        Custom main menu
            File
                New file
                Save as
                Close
            Edit
                Change canvas size
                Shortcuts
        Sidebar
            Pencil
            Eraser
            Fill bucket
            Foreground and background colors
            Color picker
        Top bar
            Brush size
        When first open
            Canvas size
                Width
                Height
            Canvas bg color
                White
                Black
                Transparent - (checker)
        When exiting and texture is not empty
            Save window
                Do you want to quit without saving?
                Save       Don't Save        Cancel
    3. Color selection
        Color picker
        Color palette swatches
    4. Undo/redo
    5. Export image
*/


main :: proc() {
    rl.InitWindow(i32(SCREEN_WIDTH), i32(SCREEN_HEIGHT), APP_TITLE)

    // Camera setup
    camera: rl.Camera2D
    camera.target = la.Vector2f32{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
    camera.offset = la.Vector2f32{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
    camera.rotation = 0.0
    camera.zoom = 1.0

    // Prepare canvas
    canvasWidth: f32 = 32
    canvasHeight: f32 = 32
    
    renderTarget: rl.RenderTexture2D = rl.LoadRenderTexture(i32(canvasWidth), i32(canvasHeight))
    canvasPosition: la.Vector2f32 = {SCREEN_WIDTH / 2 - canvasWidth / 2, SCREEN_HEIGHT / 2 - canvasHeight / 2}
    
    rl.BeginTextureMode(renderTarget)
        rl.ClearBackground(CANVAS_COLOR)
    rl.EndTextureMode()

    // Tools
    isEraserActive: bool = false
    isFillActive: bool = false

    // Colors
    foregroundColor: rl.Color = FOREGROUND_COLOR
    backgroundColor: rl.Color = BACKGROUND_COLOR
    
    rl.SetTargetFPS(120)
    
    for !rl.WindowShouldClose() {
        wheel: f32 = rl.GetMouseWheelMove()
        mousePos: la.Vector2f32 = rl.GetMousePosition()
        mouseWorldPos: la.Vector2f32 = rl.GetScreenToWorld2D(mousePos, camera)
        mappedX: f32 = ((mouseWorldPos.x - 1 - canvasPosition.x) / 32) * 32
        mappedY: f32 = 31 - (((mouseWorldPos.y - 1 - canvasPosition.y) / 32) * 32)
        
        // Tools
        // if rl.IsKeyPressed(rl.KeyboardKey.E) {
        //     isEraserActive = true
        //     isFillActive = false
        // }

        // if rl.IsKeyPressed(rl.KeyboardKey.B) {
        //     isFillActive = true
        //     isEraserActive = false
        // }

        // if rl.IsKeyPressed(rl.KeyboardKey.P) {
        //     isEraserActive = false
        //     isFillActive = false
        // }

        #partial switch rl.GetKeyPressed() {
            case rl.KeyboardKey.E:
                isEraserActive = true
                isFillActive = false
            case rl.KeyboardKey.B:
                isEraserActive = false
                isFillActive = true
            case rl.KeyboardKey.P:
                isEraserActive = false
                isFillActive = false
            case rl.KeyboardKey.X:
                foregroundColor, backgroundColor = backgroundColor, foregroundColor
            case rl.KeyboardKey.D:
                foregroundColor = FOREGROUND_COLOR
                backgroundColor = BACKGROUND_COLOR
            case rl.KeyboardKey.F:
                camera.zoom = 1
                camera.target = la.Vector2f32{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
                camera.offset = la.Vector2f32{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
        }

        // Pan and zoom
        if rl.IsMouseButtonDown(rl.MouseButton.MIDDLE) {
            delta: la.Vector2f32 = rl.GetMouseDelta()
            delta = delta * (-1 / camera.zoom)
            camera.target = camera.target + delta
        }

        if wheel != 0 {
            camera.offset = mousePos
            camera.target = mouseWorldPos
            zoomIncrement: f32 = 1

            camera.zoom += wheel * zoomIncrement
            if camera.zoom < 0.25 {
                camera.zoom = 0.25
            }
        }

        // Drawing on canvas
        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
            rl.BeginTextureMode(renderTarget)
                if isEraserActive {
                    rl.DrawPixelV({mappedX, mappedY}, CANVAS_COLOR)
                } else if isFillActive {
                    rl.ClearBackground(foregroundColor)
                } else {
                    rl.DrawPixelV({mappedX, mappedY}, foregroundColor)
                }
            rl.EndTextureMode()
        }

        // Drawing application
        rl.BeginDrawing()
            rl.ClearBackground(SCREEN_BG_COLOR)

            rl.BeginMode2D(camera)
                rl.DrawTextureV(renderTarget.texture, canvasPosition, CANVAS_COLOR)
                
                // Pixel preview
                if isEraserActive {
                    rl.DrawPixelV(mouseWorldPos - 1, CANVAS_COLOR)
                } else if isFillActive {
                    rl.DrawPixelV(mouseWorldPos - 1, foregroundColor)
                } else {
                    rl.DrawPixelV(mouseWorldPos - 1, foregroundColor)
                }
            rl.EndMode2D()

        rl.EndDrawing()
    }

    rl.UnloadRenderTexture(renderTarget)
    rl.CloseWindow()
}