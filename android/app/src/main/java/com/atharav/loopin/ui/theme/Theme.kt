package com.atharav.loopin.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val BgDark = Color(0xFF14171E)
val SurfaceDark = Color(0xFF1E222D)
val CardDark = Color(0xFF262C3A)
val AccentPurple = Color(0xFF8B5CF6)
val ProductiveGreen = Color(0xFF10B981)
val WastefulAmber = Color(0xFFF59E0B)
val NeutralBlue = Color(0xFF3B82F6)
val TextPrimary = Color(0xFFF1F5F9)
val TextSecondary = Color(0xFF94A3B8)

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
