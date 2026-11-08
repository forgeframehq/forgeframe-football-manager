package com.forgeframe.football

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.random.Random

private val bg = Color(0xFF07111D)
private val panel = Color(0xFF132639)
private val edge = Color(0xFF38506A)
private val lime = Color(0xFFB8F34C)
private val white = Color(0xFFF2F5F9)
private val muted = Color(0xFF9AAEC2)
data class Player(val name:String,val pos:String,val ovr:Int,val pot:Int,val fee:Int)
private val squad = listOf(
 Player("E. Warren","GK",69,77,3),Player("D. Mercer","RB",67,74,2),
 Player("J. Okoro","CB",72,80,5),Player("M. Bennett","CB",70,75,4),
 Player("A. Silva","LB",68,78,3),Player("S. Park","CDM",71,82,6),
 Player("L. Hayes","CM",73,79,7),Player("R. Duarte","CM",70,84,5),
 Player("F. Nordin","RW",75,83,10),Player("T. Walsh","ST",74,86,9),
 Player("K. Mensah","LW",72,85,8))
private val transfers = listOf(
 Player("Mateo Rivas","ST",77,88,19),Player("Noah Fischer","CM",75,87,15),
 Player("Amir Diallo","CB",74,85,12),Player("Kenji Sato","RW",71,91,11),
 Player("Oliver Brooks","GK",76,82,13),Player("Lucas Moreau","LB",70,86,7))
private val teams = listOf("Northbridge Athletic","Eastport United","Kingsford Town","Westhaven FC")
class MainActivity:ComponentActivity() {
 override fun onCreate(savedInstanceState:Bundle?) {
  super.onCreate(savedInstanceState)
  window.statusBarColor = android.graphics.Color.rgb(7,17,29)
  window.navigationBarColor = android.graphics.Color.rgb(7,17,29)
  val prefs = getSharedPreferences("career",MODE_PRIVATE)
  setContent {
   var club by remember { mutableStateOf(prefs.getString("club","") ?: "") }
   var tab by remember { mutableStateOf(0) }
   var sub by remember { mutableStateOf(0) }
   var budget by remember { mutableIntStateOf(prefs.getInt("budget",40)) }
   var played by remember { mutableIntStateOf(prefs.getInt("played",0)) }
   var points by remember { mutableIntStateOf(prefs.getInt("points",0)) }
   var wins by remember { mutableIntStateOf(prefs.getInt("wins",0)) }
   var formation by remember { mutableStateOf(prefs.getString("formation","4-3-3") ?: "4-3-3") }
   var mentality by remember { mutableStateOf(prefs.getString("mentality","Balanced") ?: "Balanced") }
   var training by remember { mutableIntStateOf(prefs.getInt("training",1)) }
   var youth by remember { mutableIntStateOf(prefs.getInt("youth",1)) }
   var roster by remember { mutableStateOf(squad + transfers.filter { prefs.getBoolean("signed_${it.name}",false) }) }
   var report by remember { mutableStateOf("") }
   val save = {
    prefs.edit().putInt("budget",budget).putInt("played",played)
     .putInt("points",points).putInt("wins",wins).putString("club",club)
     .putString("formation",formation).putString("mentality",mentality)
     .putInt("training",training).putInt("youth",youth).apply()
   }
   MaterialTheme(colorScheme=darkColorScheme(background=bg,surface=panel,primary=lime,onPrimary=bg,onSurface=white)) {
    Column(Modifier.fillMaxSize().background(bg).systemBarsPadding()) {
     if(club.isEmpty()){
      Header("FORGEFRAME","THE ROAD TO GLORY")
      Text("BUILD YOUR LEGACY",Modifier.padding(20.dp),fontSize=28.sp,fontWeight=FontWeight.Black,color=white)
      Text("Choose a lower division club to begin your career.",Modifier.padding(horizontal=20.dp),color=muted)
      Spacer(Modifier.height(20.dp))
      teams.forEachIndexed { index,name ->
       CardBox(Modifier.padding(horizontal=16.dp,vertical=6.dp).fillMaxWidth().clickable {
        club=name; budget=40-index*4; save()
       }) {
        Row(verticalAlignment=Alignment.CenterVertically) {
         Crest(name)
         Spacer(Modifier.width(14.dp))
         Column {
          Text(name,color=white,fontWeight=FontWeight.Bold,fontSize=18.sp)
          Text("Division 4  ·  Transfer fund €${40-index*4}M",color=muted,fontSize=12.sp)
         }
         Spacer(Modifier.weight(1f))
         Icon(Icons.Default.ChevronRight,null,tint=lime)
        }
       }
      }
     } else {
      Header("FORGEFRAME FC",club.uppercase())
      val names=listOf("HOME","SQUAD","TACTICS","MARKET","CLUB")
      val subOptions=listOf(
       listOf("Overview","Fixtures"),listOf("Players","Development"),
       listOf("Formation","Instructions"),listOf("Scout","Shortlist"),
       listOf("Facilities","Finances"))
      Row(Modifier.fillMaxWidth().background(panel).padding(horizontal=10.dp,vertical=8.dp),horizontalArrangement=Arrangement.spacedBy(7.dp)) {
       subOptions[tab].forEachIndexed { i,label ->
        SmallTab(label,sub==i,Modifier.weight(1f)){sub=i}
       }
      }
      Box(Modifier.weight(1f).fillMaxWidth()) {
       when(tab) {
        0 -> if(sub==0) {
         Column(Modifier.fillMaxSize().padding(16.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
          Section("MANAGER HUB")
          CardBox(Modifier.fillMaxWidth()) {
           Text("NEXT MATCH  ·  LEAGUE FOUR",color=lime,fontSize=12.sp,fontWeight=FontWeight.Bold)
           Spacer(Modifier.height(12.dp))
           Text("$club",fontSize=22.sp,color=white,fontWeight=FontWeight.ExtraBold)
           Text("VS  RIVERTON CITY",fontSize=17.sp,color=muted)
           Spacer(Modifier.height(16.dp))
           GameButton("PLAY NEXT MATCH",Icons.Default.PlayArrow) {
            val own=(0..3).random()+if(mentality=="Attacking") 1 else 0
            val opp=(0..3).random()
            played++; if(own>opp){wins++;points+=3}else if(own==opp)points++
            budget+=if(own>opp)2 else 1
            report="$club  $own - $opp  Riverton City";save()
           }
          }
          if(report.isNotBlank()) CardBox(Modifier.fillMaxWidth()) { Text("FULL TIME",color=lime);Text(report,color=white,fontSize=19.sp,fontWeight=FontWeight.Bold) }
          Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
           Metric("PLAYED","$played",Modifier.weight(1f))
           Metric("POINTS","$points",Modifier.weight(1f))
           Metric("WINS","$wins",Modifier.weight(1f))
          }
          CardBox(Modifier.fillMaxWidth()) {
           Text("CAREER OBJECTIVE",color=lime,fontWeight=FontWeight.Bold)
           Text("Build a competitive squad, strengthen your facilities and win promotion.",color=muted)
          }
         }
        } else Column(Modifier.padding(16.dp)) {
         Section("SEASON RECORD")
         CardBox(Modifier.fillMaxWidth()){
          Text("Fixtures played: $played",color=white)
          Text("Wins: $wins  •  Points: $points",color=muted)
          Text("Next opponent: Riverton City",color=muted)
         }
        }
        1 -> Column(Modifier.fillMaxSize().padding(12.dp)) {
         Section(if(sub==0)"FIRST TEAM" else "PLAYER DEVELOPMENT")
         Text("${roster.size} PLAYERS  •  FORMATION $formation",Modifier.padding(8.dp),color=muted,fontSize=12.sp)
         LazyColumn(verticalArrangement=Arrangement.spacedBy(7.dp)) {
          items(roster) { p -> PlayerRow(p,if(sub==0)"VALUE €${p.fee}M" else "POTENTIAL ${p.pot}") }
         }
        }
        2 -> Column(Modifier.fillMaxSize().padding(14.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
         Section(if(sub==0)"TEAM FORMATION" else "TEAM INSTRUCTIONS")
         if(sub==0){
          Row(horizontalArrangement=Arrangement.spacedBy(7.dp)){
           listOf("4-3-3","4-4-2","4-2-3-1").forEach { f ->
            SmallTab(f,formation==f,Modifier.weight(1f)){formation=f;save()}
           }
          }
          Pitch(formation,Modifier.fillMaxWidth().weight(1f))
         } else {
          Text("TEAM MENTALITY",color=muted)
          listOf("Defensive","Balanced","Attacking").forEach { m ->
           CardBox(Modifier.fillMaxWidth().clickable { mentality=m;save() }) {
            Row {
             Text(m,color=if(mentality==m)lime else white,fontWeight=FontWeight.Bold)
             Spacer(Modifier.weight(1f))
             if(mentality==m) Icon(Icons.Default.CheckCircle,null,tint=lime)
            }
           }
          }
          Text("Your tactical approach influences the match simulation.",color=muted)
         }
        }
        3 -> Column(Modifier.fillMaxSize().padding(12.dp)) {
         Section(if(sub==0)"TRANSFER MARKET" else "SIGNED PLAYERS")
         Text("AVAILABLE BUDGET  €${budget}M",Modifier.padding(8.dp),color=lime,fontWeight=FontWeight.Bold)
         val available=if(sub==0) transfers.filter { it !in roster } else roster.filter { it in transfers }
         LazyColumn(verticalArrangement=Arrangement.spacedBy(8.dp)) {
          items(available) { p ->
           CardBox(Modifier.fillMaxWidth()) {
            PlayerRowContent(p,"POT ${p.pot}  •  €${p.fee}M")
            if(sub==0) {
             Spacer(Modifier.height(10.dp))
             Button(onClick={
              if(budget>=p.fee) {
               budget-=p.fee;roster=roster+p
               prefs.edit().putBoolean("signed_${p.name}",true).apply();save()
              }
             },enabled=budget>=p.fee,colors=ButtonDefaults.buttonColors(containerColor=lime,contentColor=bg),modifier=Modifier.fillMaxWidth()) {
              Text(if(budget>=p.fee)"SIGN PLAYER  ·  €${p.fee}M" else "INSUFFICIENT FUNDS")
             }
            }
           }
          }
         }
        }
        4 -> Column(Modifier.fillMaxSize().padding(16.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
         Section(if(sub==0)"CLUB DEVELOPMENT" else "FINANCIAL OVERVIEW")
         if(sub==0) {
          listOf("Training Centre" to training,"Youth Academy" to youth).forEach { (name,level) ->
           CardBox(Modifier.fillMaxWidth()){
            Text(name,color=white,fontWeight=FontWeight.Bold,fontSize=19.sp)
            Text("LEVEL $level / 5",color=muted)
            Spacer(Modifier.height(10.dp))
            Button(onClick={
             if(name=="Training Centre") training++ else youth++
             budget-=8;save()
            },enabled=budget>=8&&level<5,colors=ButtonDefaults.buttonColors(containerColor=lime,contentColor=bg)) {
             Text("UPGRADE  ·  €8M")
            }
           }
          }
         } else {
          Metric("TRANSFER BUDGET","€${budget}M",Modifier.fillMaxWidth())
          Metric("TRAINING CENTRE","LEVEL $training",Modifier.fillMaxWidth())
          Metric("YOUTH ACADEMY","LEVEL $youth",Modifier.fillMaxWidth())
         }
        }
       }
      }
      Row(Modifier.fillMaxWidth().background(panel).padding(vertical=7.dp),horizontalArrangement=Arrangement.SpaceEvenly) {
       val icons=listOf(Icons.Default.Home,Icons.Default.Groups,Icons.Default.SportsSoccer,Icons.Default.SwapHoriz,Icons.Default.Stadium)
       names.forEachIndexed { i,name ->
        Column(Modifier.weight(1f).clickable {tab=i;sub=0}.padding(vertical=6.dp),horizontalAlignment=Alignment.CenterHorizontally) {
         Icon(icons[i],null,tint=if(tab==i)lime else muted,modifier=Modifier.size(23.dp))
         Spacer(Modifier.height(5.dp))
         Text(name,color=if(tab==i)lime else muted,fontSize=10.sp,fontWeight=FontWeight.Bold)
        }
       }
      }
     }
    }
   }
  }
 }
}
@Composable private fun Header(brand:String,sub:String) {
 Column(Modifier.fillMaxWidth().background(Brush.horizontalGradient(listOf(panel,bg))).padding(16.dp)) {
  Text(brand,color=lime,fontSize=11.sp,fontWeight=FontWeight.Black,letterSpacing=2.sp)
  Text(sub,color=white,fontSize=19.sp,fontWeight=FontWeight.Black,maxLines=1)
 }
}
@Composable private fun Section(title:String) {
 Text(title,color=white,fontSize=22.sp,fontWeight=FontWeight.Black,letterSpacing=1.sp,modifier=Modifier.padding(bottom=5.dp))
}
@Composable private fun CardBox(modifier:Modifier=Modifier,body:@Composable ColumnScope.()->Unit) {
 Column(modifier.background(panel,RoundedCornerShape(15.dp)).border(1.dp,edge,RoundedCornerShape(15.dp)).padding(15.dp),content=body)
}
@Composable private fun Metric(label:String,value:String,modifier:Modifier=Modifier) {
 CardBox(modifier) { Text(label,color=muted,fontSize=10.sp); Text(value,color=lime,fontSize=23.sp,fontWeight=FontWeight.Black) }
}
@Composable private fun Crest(name:String) {
 Box(Modifier.size(46.dp).background(lime.copy(alpha=.13f),CircleShape).border(1.dp,lime,CircleShape),contentAlignment=Alignment.Center){
  Text(name.split(" ").take(2).joinToString(""){it.take(1)},color=lime,fontWeight=FontWeight.Black)
 }
}
@Composable private fun PlayerRow(p:Player,detail:String){
 CardBox(Modifier.fillMaxWidth()){PlayerRowContent(p,detail)}
}
@Composable private fun PlayerRowContent(p:Player,detail:String){
 Row(verticalAlignment=Alignment.CenterVertically){
  Box(Modifier.size(46.dp).background(lime,RoundedCornerShape(9.dp)),contentAlignment=Alignment.Center) {
   Text("${p.ovr}",color=bg,fontSize=21.sp,fontWeight=FontWeight.Black)
  }
  Spacer(Modifier.width(12.dp))
  Column {
   Text(p.name,color=white,fontSize=16.sp,fontWeight=FontWeight.Bold)
   Text("${p.pos}  •  $detail",color=muted,fontSize=12.sp)
  }
 }
}
@Composable private fun SmallTab(text:String,selected:Boolean,modifier:Modifier=Modifier,onClick:()->Unit) {
 Box(modifier.background(if(selected)lime else edge.copy(alpha=.45f),RoundedCornerShape(8.dp)).clickable(onClick=onClick).padding(vertical=10.dp,horizontal=5.dp),contentAlignment=Alignment.Center){
  Text(text,color=if(selected)bg else white,fontSize=12.sp,fontWeight=FontWeight.Bold,maxLines=1)
 }
}
@Composable private fun GameButton(text:String,icon:ImageVector,onClick:()->Unit){
 Button(onClick=onClick,modifier=Modifier.fillMaxWidth().height(54.dp),colors=ButtonDefaults.buttonColors(containerColor=lime,contentColor=bg),shape=RoundedCornerShape(10.dp)){
  Icon(icon,null);Spacer(Modifier.width(8.dp));Text(text,fontWeight=FontWeight.Black)
 }
}
@Composable private fun Pitch(formation:String,modifier:Modifier=Modifier){
 val lines=when(formation){
  "4-4-2" -> listOf(2,4,4,1)
  "4-2-3-1" -> listOf(1,3,2,4,1)
  else -> listOf(3,3,4,1)
 }
 Box(modifier.background(Brush.verticalGradient(listOf(Color(0xFF245C4B),Color(0xFF102E2A))),RoundedCornerShape(14.dp)).border(2.dp,Color.White.copy(alpha=.45f),RoundedCornerShape(14.dp))){
  Canvas(Modifier.fillMaxSize().padding(12.dp)) {
   val lineColor=Color.White.copy(alpha=.35f)
   drawLine(lineColor,Offset(0f,size.height/2),Offset(size.width,size.height/2),2f)
   drawCircle(lineColor,radius=size.width*.16f,center=Offset(size.width/2,size.height/2),style=androidx.compose.ui.graphics.drawscope.Stroke(2f))
   drawRect(lineColor,topLeft=Offset(size.width*.2f,0f),size=androidx.compose.ui.geometry.Size(size.width*.6f,size.height*.13f),style=androidx.compose.ui.graphics.drawscope.Stroke(2f))
   drawRect(lineColor,topLeft=Offset(size.width*.2f,size.height*.87f),size=androidx.compose.ui.geometry.Size(size.width*.6f,size.height*.13f),style=androidx.compose.ui.graphics.drawscope.Stroke(2f))
  }
  Column(Modifier.fillMaxSize().padding(vertical=28.dp,horizontal=12.dp),verticalArrangement=Arrangement.SpaceBetween){
   lines.forEachIndexed { r,count ->
    Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceEvenly) {
     repeat(count) { i ->
      Box(Modifier.size(38.dp).background(if(r==lines.lastIndex)Color(0xFFECC56A) else lime,CircleShape).border(2.dp,bg,CircleShape),contentAlignment=Alignment.Center){
       Text(if(r==lines.lastIndex)"GK" else "${r+1}",color=bg,fontWeight=FontWeight.Black,fontSize=12.sp)
      }
     }
    }
   }
  }
 }
}
