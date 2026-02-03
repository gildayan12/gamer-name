shader_type canvas_item;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    
    // Standard VFX Chroma Key Formula + Despill
    // Logic: Is Green significantly brighter than the MAX of Red and Blue?
    
    float sensitivity = 1.05; // Slightly stricter (was 1.1)
    float max_rb = max(col.r, col.b);
    
    // 1. Transparency Check
    if (col.g > max_rb * sensitivity && col.g > 0.25) {
        col.a = 0.0;
    }
    
    // 2. DESPILL (The Fix for Halos)
    // If a pixel survives the cut but is still "Greenish" (e.g. skin edge), 
    // we clamp the Green channel down to the Red/Blue level.
    // This turns "Green Halo" into "Neutral Gray/Skin Shadow".
    if (col.a > 0.0 && col.g > max_rb) {
        col.g = max_rb; 
    }
    
    // Cleanup: Distance Check for Pure Green
    if (distance(col.rgb, vec3(0.0, 1.0, 0.0)) < 0.5) {
        col.a = 0.0;
    }
    
    COLOR = col;
}
