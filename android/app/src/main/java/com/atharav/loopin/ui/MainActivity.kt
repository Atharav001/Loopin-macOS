package com.atharav.loopin.ui

import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.lifecycleScope
import com.atharav.loopin.classifier.ClassifierEngine
import com.atharav.loopin.data.LoopinDatabase
import com.atharav.loopin.model.TimesheetEntry
import com.atharav.loopin.service.HourlyLoggingService
import com.atharav.loopin.ui.theme.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : ComponentActivity() {
    private lateinit var db: LoopinDatabase

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        db = LoopinDatabase.getInstance(applicationContext)

        setContent {
            LoopinTheme {
                MainScreen(
                    onStartService = { startHourlyNotificationService() },
                    onStopService = { stopHourlyNotificationService() },
                    onSaveEntry = { rawText, kind ->
                        lifecycleScope.launch(Dispatchers.IO) {
                            val rules = db.classificationDao().getAllRules()
                            val (cat, subcat, prod) = ClassifierEngine.classify(rawText, rules)
                            val now = System.currentTimeMillis()
                            val entry = TimesheetEntry(
                                kind = kind,
                                startAt = now - 3600000,
                                endAt = now,
                                rawText = rawText,
                                inputMethod = "typed",
                                category = cat,
                                subcategory = subcat,
                                productivity = prod
                            )
                            db.timesheetDao().insertEntry(entry)
                        }
                    },
                    db = db
                )
            }
        }
    }

    private fun startHourlyNotificationService() {
        val intent = Intent(this, HourlyLoggingService::class.java).apply {
            action = HourlyLoggingService.ACTION_START_HOURLY
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopHourlyNotificationService() {
        val intent = Intent(this, HourlyLoggingService::class.java).apply {
            action = HourlyLoggingService.ACTION_STOP_HOURLY
        }
        startService(intent)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    onStartService: () -> Unit,
    onStopService: () -> Unit,
    onSaveEntry: (String, String) -> Unit,
    db: LoopinDatabase
) {
    var selectedTab by remember { mutableStateOf("logged") } // "logged" or "planned"
    var showQuickLogDialog by remember { mutableStateOf(false) }
    var serviceRunning by remember { mutableStateOf(false) }
    val entries by db.timesheetDao().getEntriesByKind(selectedTab).collectAsState(initial = emptyList())

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "Loopin",
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary,
                            fontSize = 20.sp
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = AccentPurple.copy(alpha = 0.2f),
                            modifier = Modifier.padding(vertical = 2.dp)
                        ) {
                            Text(
                                text = "Cross-Platform Sync",
                                color = AccentPurple,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                },
                actions = {
                    IconButton(onClick = {
                        serviceRunning = !serviceRunning
                        if (serviceRunning) onStartService() else onStopService()
                    }) {
                        Icon(
                            imageVector = Icons.Default.Notifications,
                            contentDescription = "Toggle Hourly Notifications",
                            tint = if (serviceRunning) ProductiveGreen else TextSecondary
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = BgDark
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showQuickLogDialog = true },
                containerColor = AccentPurple,
                contentColor = Color.White
            ) {
                Icon(Icons.Default.Add, contentDescription = "Quick Log")
            }
        },
        containerColor = BgDark
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp)
        ) {
            // Segmented Bar: Logged (Actual) vs Planned
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(SurfaceDark)
                    .padding(4.dp)
            ) {
                TabButton(
                    title = "⚡ Actual Logged",
                    isSelected = selectedTab == "logged",
                    modifier = Modifier.weight(1f)
                ) {
                    selectedTab = "logged"
                }
                TabButton(
                    title = "📅 Planned Rails",
                    isSelected = selectedTab == "planned",
                    modifier = Modifier.weight(1f)
                ) {
                    selectedTab = "planned"
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Sync status summary pill
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(8.dp))
                    .background(SurfaceDark)
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(ProductiveGreen)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Supabase & GCal Connected",
                        fontSize = 12.sp,
                        color = TextSecondary
                    )
                }
                Text(
                    text = "${entries.size} blocks",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = AccentPurple
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Entries List
            if (entries.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "No ${selectedTab} blocks for today.\nTap + to create one or wait for hourly prompt.",
                        color = TextSecondary,
                        fontSize = 14.sp
                    )
                }
            } else {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    items(entries) { entry ->
                        EntryCard(entry)
                    }
                }
            }
        }
    }

    if (showQuickLogDialog) {
        QuickLogDialog(
            currentKind = selectedTab,
            onDismiss = { showQuickLogDialog = false },
            onConfirm = { text ->
                onSaveEntry(text, selectedTab)
                showQuickLogDialog = false
            }
        )
    }
}

@Composable
fun TabButton(
    title: String,
    isSelected: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .background(if (isSelected) AccentPurple else Color.Transparent)
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = title,
            color = if (isSelected) Color.White else TextSecondary,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            fontSize = 13.sp
        )
    }
}

@Composable
fun EntryCard(entry: TimesheetEntry) {
    val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
    val startStr = timeFormat.format(Date(entry.startAt))
    val endStr = timeFormat.format(Date(entry.endAt))

    val prodColor = when (entry.productivity) {
        "productive" -> ProductiveGreen
        "wasteful" -> WastefulAmber
        else -> NeutralBlue
    }

    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = CardDark),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .padding(14.dp)
                .fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = entry.rawText.ifEmpty { "(${entry.category})" },
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "$startStr - $endStr",
                        fontSize = 12.sp,
                        color = TextSecondary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "• ${entry.category}",
                        fontSize = 12.sp,
                        color = TextSecondary
                    )
                }
            }

            Surface(
                shape = RoundedCornerShape(6.dp),
                color = prodColor.copy(alpha = 0.2f)
            ) {
                Text(
                    text = entry.productivity.replaceFirstChar { it.uppercase() },
                    color = prodColor,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                )
            }
        }
    }
}

@Composable
fun QuickLogDialog(
    currentKind: String,
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    var text by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (currentKind == "logged") "Log Past Interval" else "Plan Next Block",
                color = TextPrimary,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column {
                Text(
                    text = "Enter what you did (e.g. 'Coding authentication', 'Watched COD tournament', 'Scrolling instagram'):",
                    color = TextSecondary,
                    fontSize = 13.sp
                )
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = text,
                    onValueChange = { text = it },
                    placeholder = { Text("What did you do?", color = TextSecondary.copy(alpha = 0.6f)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = false,
                    maxLines = 3
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (text.isNotBlank()) onConfirm(text)
                },
                colors = ButtonDefaults.buttonColors(containerColor = AccentPurple)
            ) {
                Text("Save", color = Color.White)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = TextSecondary)
            }
        },
        containerColor = SurfaceDark
    )
}
