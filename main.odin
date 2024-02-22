package main

import "core:fmt"
import la "core:math/linalg"

import rl "vendor:raylib"


// CONSTANTS
APP_TITLE: cstring = "Pixel Editor"
SCREEN_WIDTH: f32 = 800
SCREEN_HEIGHT: f32 = 500
SCREEN_BG_COLOR: rl.Color = { 109, 104, 117, 255 }
TEXT_COLOR: rl.Color = { 255, 205, 178, 255 }
PRIMARY_COLOR: rl.Color = { 255,180,162, 255 }
SECONDARY_COLOR: rl.Color = { 229, 152, 155, 255 }
ACCENT_COLOR: rl.Color = { 181, 131, 141, 255 }


main :: proc() {
    rl.InitWindow(i32(SCREEN_WIDTH), i32(SCREEN_HEIGHT), APP_TITLE)

    camera: rl.Camera2D
    camera.target = la.Vector2f32{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
    camera.offset = la.Vector2f32{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
    camera.rotation = 0.0
    camera.zoom = 1.0

    canvasWidth: f32 = 128
    canvasHeight: f32 = 128
    
    renderTarget: rl.RenderTexture2D = rl.LoadRenderTexture(i32(canvasWidth), i32(canvasHeight))
    canvasPosition: la.Vector2f32 = {SCREEN_WIDTH / 2 - canvasWidth / 2, SCREEN_HEIGHT / 2 - canvasHeight / 2}
    canvas: rl.Rectangle = { canvasPosition.x, canvasPosition.y, canvasWidth, -canvasHeight }
    
    rl.BeginTextureMode(renderTarget)
        rl.ClearBackground(SECONDARY_COLOR)
    rl.EndTextureMode()
    
    rl.SetTargetFPS(120)
    
    for !rl.WindowShouldClose() {
        mousePos: la.Vector2f32

        camera.zoom += rl.GetMouseWheelMove() * 0.05

        if rl.IsKeyPressed(rl.KeyboardKey.F) {
            camera.zoom = 1
        }

        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            mousePos = rl.GetMousePosition()
        }

        rl.BeginDrawing()
            rl.ClearBackground(SCREEN_BG_COLOR)

            rl.BeginMode2D(camera)
                rl.DrawTextureRec(renderTarget.texture, canvas, canvasPosition, SECONDARY_COLOR)
                rl.DrawPixelV(mousePos, PRIMARY_COLOR)
            rl.EndMode2D()

        rl.EndDrawing()
    }

    rl.CloseWindow()
}