package com.atharav.loopin.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// MARK: - OLED Black & Strong Minimal Color Palette
val BgDark = Color(0xFF000000)          // True OLED Pitch Black
val SurfaceDark = Color(0xFF0E0E11)     // Minimal Obsidian Surface
val CardDark = Color(0xFF16161A)        // Deep Zinc-950 Card Container
val CardDarkHover = Color(0xFF222228)   // Active Hover Surface
val BorderDark = Color(0xFF27272F)       // Sharp subtle minimal stroke
val AccentPurple = Color(0xFF8B5CF6)     // High-contrast Royal Violet Accent
val ProductiveGreen = Color(0xFF10B981)  // Emerald Status
val WastefulAmber = Color(0xFFF59E0B)    // Amber Status
val NeutralBlue = Color(0xFF3B82F6)      // Cyan/Azure Status
val TextPrimary = Color(0xFFFAFAFA)      // Pure High-Contrast White
val TextSecondary = Color(0xFFA1A1AA)    // Slate/Zinc 400
val TextMuted = Color(0xFF71717A)        // Slate/Zinc 500

// MARK: - Boxy / Square Headings & Professional Typography Hierarchy
val TypographyHierarchy = object {
    // 1. Display: High-impact boxy uppercase header
    val DisplayBoxy = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontWeight = FontWeight.Black,
        fontSize = 22.sp,
        letterSpacing = 1.5.sp,
        color = TextPrimary
    )
    
    // 2. Large Title: Boxy square section title
    val TitleLargeBoxy = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontWeight = FontWeight.Bold,
        fontSize = 17.sp,
        letterSpacing = 0.8.sp,
        color = TextPrimary
    )
    
    // 3. Medium Title / Card Header: Crisp geometric monospace
    val TitleMediumBoxy = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontWeight = FontWeight.SemiBold,
        fontSize = 14.sp,
        letterSpacing = 0.5.sp,
        color = TextPrimary
    )
    
    // 4. Subheadline / Tag: Sharp tracked uppercase metadata
    val SubheadBoxy = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontWeight = FontWeight.Bold,
        fontSize = 11.sp,
        letterSpacing = 1.sp,
        color = TextSecondary
    )
    
    // 5. Body Primary: Balanced, highly legible sans-serif for content
    val BodyPrimary = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 13.sp,
        lineHeight = 18.sp,
        letterSpacing = 0.2.sp,
        color = TextPrimary
    )
    
    // 6. Body Secondary / Metadata
    val BodySecondary = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        letterSpacing = 0.1.sp,
        color = TextSecondary
    )
    
    // 7. Micro Monospace / Timestamp
    val TimestampMono = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontWeight = FontWeight.Normal,
        fontSize = 11.sp,
        letterSpacing = 0.3.sp,
        color = TextSecondary
    )
}

private val DarkColorScheme = darkColorScheme(
    primary = AccentPurple,
    onPrimary = Color.White,
    secondary = ProductiveGreen,
    onSecondary = Color.White,
    background = BgDark,
    surface = SurfaceDark,
    onBackground = TextPrimary,
    onSurface = TextPrimary
)

@Composable
fun LoopinTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        content = content
    )
}
