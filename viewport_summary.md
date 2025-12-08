# Using ViewportFrames for 3D Part Previews in Roblox

## Summary

If you need to display a lot of parts in a list with visual previews,
**ViewportFrames** are the best Roblox-native method. They let you show
a live 3D render of any model directly in UI without uploading images.

## Why ViewportFrames Work Well

-   No need to upload images manually\
-   Works for hundreds of parts\
-   Previews automatically update if models change\
-   Perfect for catalogs, inventories, crafting menus, etc.\
-   Efficient if only visible items are rendered

## Performance Tips

-   Only keep \~20 previews active at once (UI virtualization)
-   Use simplified models where possible
-   Avoid unnecessary animations
-   Reuse ViewportFrames when scrolling

## Basic Implementation Steps

1.  Create a `ViewportFrame` inside each list entry
2.  Clone your model into the frame
3.  Add a `Camera` object inside the frame
4.  Position the camera to frame the model
5.  Roblox renders a 2D preview automatically

## Example Script

``` lua
local function createPreview(model, viewportFrame)
    local clone = model:Clone()
    clone.Parent = viewportFrame

    local camera = Instance.new("Camera")
    camera.Parent = viewportFrame
    viewportFrame.CurrentCamera = camera

    local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
    if not primary then return end

    local size = clone:GetExtentsSize().Magnitude
    camera.CFrame = CFrame.new(primary.Position + Vector3.new(size, size, size), primary.Position)
end
```

## Conclusion

Using ViewportFrames is the recommended, scalable, and high-performance
approach for showing a lot of part previews in Roblox UI. It requires no
uploads, looks clean, and works efficiently when managed correctly.
