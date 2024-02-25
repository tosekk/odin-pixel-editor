package main

import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

import rl "vendor:raylib"


// CONSTANTS
APP_TITLE: cstring = "Pixel Editor"
SCREEN_WIDTH: f32 = 800
SCREEN_HEIGHT: f32 = 500
SCREEN_BG_COLOR: rl.Color = { 109, 104, 117, 255 }
MENU_COLOR: rl.Color = { 200, 200, 200, 255 }
BUTTON_COLOR: rl.Color = { 175, 175, 175, 255 }
FOREGROUND_COLOR: rl.Color = { 0, 0, 0, 255 }
BACKGROUND_COLOR: rl.Color = { 255, 255, 255, 255 }
CANVAS_COLOR: rl.Color = { 255, 255, 255, 255 }
DEFAULT_CANVAS_WIDTH: f32 = 64
DEFAULT_CANVAS_HEIGHT: f32 = 64

// TO-DO
/*
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
    camera.target = la.Vector2f32{ SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2 }
    camera.offset = la.Vector2f32{ SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2 }
    camera.rotation = 0.0
    camera.zoom = 1.0

    // Prepare canvas
    width: [dynamic]rune = {'6', '4'}
    height: [dynamic]rune = {'6', '4'}
    editingWidth: bool = false
    editingHeight: bool = false
    unit: string = "px"
    key: rune
    canvasWidth: f32 = DEFAULT_CANVAS_WIDTH
    canvasHeight: f32 = DEFAULT_CANVAS_HEIGHT
    
    renderTarget: rl.RenderTexture2D = rl.LoadRenderTexture(i32(canvasWidth), i32(canvasHeight))
    canvasPosition: la.Vector2f32 = { SCREEN_WIDTH / 2 - canvasWidth / 2, SCREEN_HEIGHT / 2 - canvasHeight / 2 }
    
    rl.BeginTextureMode(renderTarget)
        rl.ClearBackground(CANVAS_COLOR)
    rl.EndTextureMode()

    // Canvas pop-up
    createPopupOn: bool = true
    mouseOnText: bool = false
    createPopup: rl.Rectangle = { SCREEN_WIDTH / 2 - 65, SCREEN_HEIGHT / 2 - 55, 130, 110 }
    createButton: rl.Rectangle = { SCREEN_WIDTH / 2 - 5, SCREEN_HEIGHT / 2 + 25, 60, 20 }
    createButtonOutline: rl.Rectangle = { SCREEN_WIDTH / 2 - 7, SCREEN_HEIGHT / 2 + 23, 64, 24 }
    widthEdit: rl.Rectangle = { SCREEN_WIDTH / 2 - 5, SCREEN_HEIGHT / 2 - 40, 60, 24 }
    widthEditOutline: rl.Rectangle = { SCREEN_WIDTH / 2 - 7, SCREEN_HEIGHT / 2 - 42, 64, 28 }
    heightEdit: rl.Rectangle = { SCREEN_WIDTH / 2 - 5, SCREEN_HEIGHT / 2 - 10, 60, 24 }
    heightEditOutline: rl.Rectangle = { SCREEN_WIDTH / 2 - 7, SCREEN_HEIGHT / 2 - 12, 64, 28 }

    // Mouse over canvas
    mouseOverCanvas: bool = false
    canvasRec: rl.Rectangle = { canvasPosition.x, canvasPosition.y, canvasWidth, canvasHeight }

    // Tools
    isEraserActive: bool = false
    isFillActive: bool = false

    // Colors
    foregroundColor: rl.Color = FOREGROUND_COLOR
    backgroundColor: rl.Color = BACKGROUND_COLOR

    // Undo and Redo
    undoStack: [dynamic]rl.Texture
    redoStack: [dynamic]rl.Texture
    state: int = 0
    
    rl.SetTargetFPS(120)
    
    for !rl.WindowShouldClose() {
        wheel: f32 = rl.GetMouseWheelMove()
        mousePos: la.Vector2f32 = rl.GetMousePosition()
        mouseWorldPos: la.Vector2f32 = rl.GetScreenToWorld2D(mousePos, camera)
        image: rl.Image
        canvasWidth = f32(strconv.atof(utf8.runes_to_string(width[:])))
        canvasHeight = f32(strconv.atof(utf8.runes_to_string(height[:])))
        canvasPosition = { SCREEN_WIDTH / 2 - canvasWidth / 2, SCREEN_HEIGHT / 2 - canvasHeight / 2 }
        canvasRec = { canvasPosition.x, canvasPosition.y, canvasWidth, canvasHeight }
        mappedX: f32 = ((mouseWorldPos.x - 1 - canvasPosition.x) / (canvasWidth / 2)) * (canvasWidth / 2)
        mappedY: f32 = (canvasHeight - 1) - (((mouseWorldPos.y - 1 - canvasPosition.y) / (canvasHeight / 2)) * (canvasHeight / 2))

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

        // Saving
        if rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) {
            if rl.IsKeyPressed(rl.KeyboardKey.S) {
                image = rl.LoadImageFromTexture(renderTarget.texture)
                rl.ImageFlipVertical(&image)
                rl.ExportImage(image, "unnamed.png")
                rl.UnloadImage(image)
            }

            if rl.IsKeyPressed(rl.KeyboardKey.Z) {
                if state > 0 {
                    renderTarget.texture = undoStack[state - 1]
                    append(&redoStack, undoStack[state - 1])
                    ordered_remove(&undoStack, state - 1)
                    state -= 1
                }
            }

            if rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT) {
                if state > 0 {
                    if rl.IsKeyPressed(rl.KeyboardKey.Z) {
                        renderTarget.texture = redoStack[state]
                        append(&undoStack, redoStack[state])
                        ordered_remove(&redoStack, state)
                        state += 1
                    }
                }
            }
        }

        // Creating canvas
        if createPopupOn {
            mouseOnText = rl.CheckCollisionPointRec(mouseWorldPos, widthEdit) || rl.CheckCollisionPointRec(mouseWorldPos, heightEdit)
            
            if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
                createPopupOn = !rl.CheckCollisionPointRec(mouseWorldPos, createButton)
                renderTarget = rl.LoadRenderTexture(i32(canvasWidth), i32(canvasHeight))
                append(&undoStack, renderTarget.texture)
                state += 1

                rl.BeginTextureMode(renderTarget)
                    rl.ClearBackground(CANVAS_COLOR)
                rl.EndTextureMode()
            }

            if mouseOnText {
                rl.SetMouseCursor(rl.MouseCursor.IBEAM)

                if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
                    if rl.CheckCollisionPointRec(mouseWorldPos, widthEdit) {
                        editingWidth = true
                        editingHeight = false
                    }
                    
                    if rl.CheckCollisionPointRec(mouseWorldPos, heightEdit) {
                        editingHeight = true
                        editingWidth = false
                    }
                }
            } else {
                rl.SetMouseCursor(rl.MouseCursor.DEFAULT)
            }

            key = rl.GetCharPressed()

            if editingWidth {
                if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
                    if len(width) >= 1 {
                        pop(&width)
                    }
                }
                
                if key >= 48 && key <= 57 {
                    append(&width, key)
                }
            }

            if editingHeight {
                if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
                    if len(height) >= 1 {
                        pop(&height)
                    }
                }
                
                if key >= 48 && key <= 57 {
                    append(&height, key)
                }
            }
        }

        // Pan and zoom
        if !createPopupOn {
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
        }

        // Mouse over canvas
        mouseOverCanvas = rl.CheckCollisionPointRec(mouseWorldPos, canvasRec)

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

        if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) && !createPopupOn {
            append(&undoStack, renderTarget.texture)
            state += 1
        }

        // Drawing application
        rl.BeginDrawing()
            rl.ClearBackground(SCREEN_BG_COLOR)

            rl.BeginMode2D(camera)
                if createPopupOn {
                    rl.DrawRectangleRec(createPopup, MENU_COLOR)
                    rl.DrawRectangleRec(createButtonOutline, rl.BLACK)
                    rl.DrawRectangleRec(createButton, BUTTON_COLOR)
                    rl.DrawRectangleRec(widthEditOutline, rl.BLACK)
                    rl.DrawRectangleRec(widthEdit, BUTTON_COLOR)
                    rl.DrawRectangleRec(heightEditOutline, rl.BLACK)
                    rl.DrawRectangleRec(heightEdit, BUTTON_COLOR)
                    rl.DrawText("Create", i32(SCREEN_WIDTH / 2 + 5), i32(SCREEN_HEIGHT / 2 + 30), 12, rl.BLACK)
                    rl.DrawText("Width", i32(SCREEN_WIDTH / 2 - 55), i32(SCREEN_HEIGHT / 2 - 33), 12, rl.BLACK)
                    rl.DrawText("Height", i32(SCREEN_WIDTH / 2 - 55), i32(SCREEN_HEIGHT / 2 - 3), 12, rl.BLACK)
                    rl.DrawText(strings.clone_to_cstring(strings.concatenate({utf8.runes_to_string(width[:]), unit})), i32(SCREEN_WIDTH / 2), i32(SCREEN_HEIGHT / 2 - 35) , 12, rl.BLACK)
                    rl.DrawText(strings.clone_to_cstring(strings.concatenate({utf8.runes_to_string(height[:]), unit})), i32(SCREEN_WIDTH / 2), i32(SCREEN_HEIGHT / 2 - 5), 12, rl.BLACK)
                } else {
                    rl.DrawTextureV(renderTarget.texture, canvasPosition, CANVAS_COLOR)
                }
                
                previewPos: la.Vector2f32 = {math.floor(mouseWorldPos.x), math.floor(mouseWorldPos.y)}

                // Pixel preview
                if mouseOverCanvas {
                    if isEraserActive {
                        rl.DrawPixelV(previewPos, CANVAS_COLOR)
                    } else if isFillActive {
                        rl.DrawPixelV(previewPos, foregroundColor)
                    } else {
                        rl.DrawPixelV(previewPos, foregroundColor)
                    }
                }
            rl.EndMode2D()

        rl.EndDrawing()
    }

    rl.UnloadRenderTexture(renderTarget)
    rl.CloseWindow()
}