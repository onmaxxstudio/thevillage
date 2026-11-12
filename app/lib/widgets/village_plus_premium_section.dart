import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium-only experiences are distinct from the free tools below this panel.
/// Buttons show previews until enrollment and the event schedule are available.
class VillagePlusPremiumSection extends StatelessWidget {
  const VillagePlusPremiumSection({super.key,required this.onMembership});
  final VoidCallback onMembership;
  static const green=Color(0xFF003B23);
  static const gold=Color(0xFFF1CF60);
  static const cream=Color(0xFFFFFAF1);
  TextStyle _title(double size)=>TextStyle(fontFamily:'VillagePlusDisplay',fontSize:size,
    color:cream,height:1.12);
  @override
  Widget build(BuildContext context)=>LayoutBuilder(builder:(context,constraints){
    final wide=constraints.maxWidth>=600;
    final large=MediaQuery.textScalerOf(context).scale(14)>19;
    final stacked=!wide||large;
    final padding=wide?20.0:14.0;
    final cards=<Widget>[
      _experience(context,wide,0,Icons.groups_outlined,'Monthly Event',
        'Live workshops + replays, member challenge, and theme resources.','View This Month'),
      _experience(context,wide,1,Icons.volunteer_activism_outlined,'You’re Not Alone',
        'A guided weekly check-in with optional, private member support.','Check In Now'),
      _experience(context,wide,2,Icons.auto_stories_outlined,'My Growth Journey',
        'Exclusive 21-Day programs, deeper journaling, and progress tracking.','Explore Journeys'),
    ];
    return Stack(clipBehavior:Clip.none,alignment:Alignment.topCenter,children:[
      Container(key:const ValueKey('village-plus-premium-section'),margin:const EdgeInsets.only(top:12),
        padding:EdgeInsets.fromLTRB(padding,30,padding,padding),
        decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),
          gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
            colors:[Color(0xFF00492B),Color(0xFF002916)]),
          boxShadow:const[BoxShadow(color:Color(0x33372C13),blurRadius:12,offset:Offset(0,5))]),
        child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Row(children:[Expanded(child:Divider(color:gold,indent:wide?40:0,endIndent:14)),
            Expanded(flex:4,child:Text('Your growth, unfolding',textAlign:TextAlign.center,
              style:_title(wide?36:24))),
            Expanded(child:Divider(color:gold,indent:14,endIndent:wide?40:0))]),
          const SizedBox(height:10),
          Padding(padding:EdgeInsets.symmetric(horizontal:wide?70:0),child:Text.rich(TextSpan(children:[
            const TextSpan(text:'A premium addition to your Ask the Village experience, with deeper insights, exclusive experiences, guided support, and curated journeys — while '),
            const TextSpan(text:'all of your existing free tools remain available, just as always.',
              style:TextStyle(color:gold,fontWeight:FontWeight.bold,fontStyle:FontStyle.italic)),
          ]),textAlign:TextAlign.center,style:TextStyle(color:cream,fontSize:wide?17:13,height:1.3))),
          const SizedBox(height:16),
          _hero(context,wide,stacked),
          const SizedBox(height:12),
          if(stacked) ...[
            for(var i=0;i<cards.length;i++) ...[if(i>0)const SizedBox(height:10),cards[i]],
          ] else IntrinsicHeight(child:Row(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            for(var i=0;i<cards.length;i++) ...[if(i>0)const SizedBox(width:10),Expanded(child:cards[i])],
          ])),
          const SizedBox(height:10),
          Text('Member experiences preview · enrollment opening soon',textAlign:TextAlign.center,
            style:TextStyle(color:gold,fontSize:wide?12:11)),
        ])),
      Container(padding:const EdgeInsets.symmetric(horizontal:20,vertical:7),
        decoration:BoxDecoration(borderRadius:BorderRadius.circular(30),
          gradient:const LinearGradient(colors:[Color(0xFFFFE88A),Color(0xFFF2C649)])),
        child:const Row(mainAxisSize:MainAxisSize.min,children:[
          Icon(Icons.workspace_premium_outlined,color:Color(0xFF092E1D),size:24),SizedBox(width:7),
          Flexible(child:Text('VILLAGE PLUS',textAlign:TextAlign.center,style:TextStyle(color:Color(0xFF092E1D),fontSize:17,fontWeight:FontWeight.w800))),
        ])),
    ]);
  });

  Widget _hero(BuildContext context,bool wide,bool stacked)=>Container(
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),border:Border.all(color:gold,width:1.7),
      color:const Color(0xFF123D20)),
    clipBehavior:Clip.antiAlias,
    child:Padding(padding:EdgeInsets.all(wide?16:14),child:Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
      if(wide&&!stacked) ...[const Icon(Icons.calendar_month_outlined,color:gold,size:46),
        const SizedBox(width:18),Container(width:1,height:100,color:gold),const SizedBox(width:18)],
      Expanded(flex:6,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('THIS MONTH’S VILLAGE EXPERIENCE',style:TextStyle(color:gold,fontWeight:FontWeight.w700,
          fontSize:wide?15:11,letterSpacing:.5)),const SizedBox(height:6),
        Text('Making Room for Yourself',style:_title(wide?30:24)),const SizedBox(height:7),
        Text('A live gathering, guided reflection, and practical tools to help you reset, refocus, and reclaim your peace.',
          style:TextStyle(color:cream,fontSize:wide?17:13,height:1.3)),
        if(stacked) ...[const SizedBox(height:12),_button(context,'rsvp','RSVP Now',0)],
      ])),
      if(!stacked) ...[const SizedBox(width:12),Expanded(flex:4,child:Column(children:[
        const SizedBox(height:105,width:double.infinity,child:_PremiumArtwork(region:Rect.fromLTWH(850,298,340,155))),
        _button(context,'rsvp','RSVP Now',0),
      ]))],
    ])));

  Widget _experience(BuildContext context,bool wide,int index,IconData icon,String title,
    String description,String action)=>Container(
      decoration:BoxDecoration(color:green,borderRadius:BorderRadius.circular(18),
        border:Border.all(color:gold,width:1.7)),clipBehavior:Clip.antiAlias,
      child:Stack(children:[
        if(index==0)const Positioned(left:0,bottom:0,width:60,height:85,
          child:IgnorePointer(child:_PremiumArtwork(region:Rect.fromLTWH(135,553,90,100)))),
        if(index==2)const Positioned(right:0,bottom:0,width:60,height:85,
          child:IgnorePointer(child:_PremiumArtwork(region:Rect.fromLTWH(1334,550,68,107)))),
        Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:gold,size:wide?32:28),
            const SizedBox(width:10),Expanded(child:Text(title,style:_title(wide?23:22)))]),
          const SizedBox(height:9),Text(description,style:TextStyle(color:cream,fontSize:wide?17:13,height:1.3)),
          const SizedBox(height:14),_button(context,['monthly-event','member-check-in','growth-journey'][index],action,index+1),
        ])),
      ]));

  Widget _button(BuildContext context,String key,String text,int experience)=>FilledButton(
    key:ValueKey('plus-$key'),onPressed:()=>_preview(context,experience),
    style:FilledButton.styleFrom(backgroundColor:gold,foregroundColor:const Color(0xFF082A1A),
      padding:const EdgeInsets.symmetric(horizontal:10,vertical:10)),
    child:Row(mainAxisSize:MainAxisSize.min,mainAxisAlignment:MainAxisAlignment.center,children:[
      Flexible(child:Text(text,textAlign:TextAlign.center,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700))),
      const SizedBox(width:4),const Icon(Icons.chevron_right,size:18),
    ]));

  void _preview(BuildContext context,int experience){
    const titles=['Making Room for Yourself','Monthly Event','You’re Not Alone','My Growth Journey'];
    const details=[
      'A live gathering, guided reflection, and practical tools to help you reset and refocus. Dates and RSVP details will appear here when this experience opens.',
      'Member workshops, replays, a monthly challenge, and resources around one meaningful theme. This month’s schedule will appear here when membership opens.',
      'A guided weekly check-in, with optional private member support. Nothing is shared automatically. This member experience is coming soon.',
      'Exclusive 21-day programs with deeper journaling and progress tracking. Explore a meaningful focus over three weeks when this member experience opens.',
    ];
    showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,backgroundColor:cream,
      builder:(sheetContext)=>SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(24),
        child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          const Text('VILLAGE PLUS · COMING SOON',style:TextStyle(color:green,fontWeight:FontWeight.bold,fontSize:12)),
          const SizedBox(height:12),Text(titles[experience],style:TextStyle(fontFamily:'VillagePlusDisplay',fontSize:28,color:green)),
          const SizedBox(height:14),Text(details[experience],style:const TextStyle(fontSize:15,height:1.5,color:green)),
          const SizedBox(height:20),FilledButton(onPressed:(){Navigator.pop(sheetContext);onMembership();},
            style:FilledButton.styleFrom(backgroundColor:green),child:const Text('Explore Village Plus')),
          TextButton(onPressed:()=>Navigator.pop(sheetContext),child:const Text('Back to Growth Studio')),
        ]))));
  }
}

class _PremiumArtwork extends StatelessWidget {
  const _PremiumArtwork({required this.region});
  final Rect region;
  static final Future<ui.Image> _image=_load();
  static Future<ui.Image> _load()async{
    final data=await rootBundle.load('assets/images/village_plus_experiences.jpg');
    final codec=await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame=await codec.getNextFrame();codec.dispose();return frame.image;
  }
  @override
  Widget build(BuildContext context)=>ExcludeSemantics(child:FutureBuilder<ui.Image>(future:_image,
    builder:(context,snapshot)=>snapshot.hasData?CustomPaint(painter:_PremiumPainter(snapshot.data!,region)):
      const SizedBox.expand()));
}
class _PremiumPainter extends CustomPainter {
  const _PremiumPainter(this.image,this.region);
  final ui.Image image;final Rect region;
  @override
  void paint(Canvas canvas,Size size){
    final fitted=applyBoxFit(BoxFit.cover,region.size,size);
    final source=Alignment.center.inscribe(fitted.source,region);
    canvas.drawImageRect(image,source,Offset.zero&size,Paint()..filterQuality=FilterQuality.high);
  }
  @override
  bool shouldRepaint(_PremiumPainter oldDelegate)=>image!=oldDelegate.image||region!=oldDelegate.region;
}
