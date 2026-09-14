import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_content_service.dart';
import 'admin_moderation_screen.dart';

class VillageAdminScreen extends StatefulWidget {
  const VillageAdminScreen({super.key});
  @override
  State<VillageAdminScreen> createState() => _VillageAdminScreenState();
}

class _VillageAdminScreenState extends State<VillageAdminScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);

  static const builtInCommunities = <Map<String, String>>[
    {'id':'relationships','name':'Relationships','description':'For the conversations you cannot always have with people you know.','category':'Relationships','imageUrl':'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=1200&q=85'},
    {'id':'women','name':'Women','description':'Support, perspective, and connection through every season of womanhood.','category':'Life & Growth','imageUrl':'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=85'},
    {'id':'moms','name':'Moms','description':'Real talk and practical support for motherhood.','category':'Parenting','imageUrl':'https://images.unsplash.com/photo-1543342386-1f1350e27861?auto=format&fit=crop&w=1200&q=85'},
    {'id':'friendship','name':'Friendship','description':'Navigate closeness, change, conflict, and connection.','category':'Friendship','imageUrl':'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=85'},
    {'id':'wellness','name':'Wellness','description':'Gentle support for emotional and everyday wellbeing.','category':'Mental Health','imageUrl':'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1200&q=85'},
    {'id':'career','name':'Career & Purpose','description':'Work, confidence, growth, and your next move.','category':'Work & School','imageUrl':'https://images.unsplash.com/photo-1521737711867-e3b97375f902?auto=format&fit=crop&w=1200&q=85'},
    {'id':'grief','name':'Grief & Healing','description':'A softer place for loss, remembrance, and healing.','category':'Grief','imageUrl':'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=85'},
    {'id':'new_beginnings','name':'New Beginnings','description':'Moves, endings, transitions, and fresh starts.','category':'Life & Growth','imageUrl':'https://images.unsplash.com/photo-1500534623283-312aade485b7?auto=format&fit=crop&w=1200&q=85'},
    {'id':'caregivers','name':'Caregivers','description':'Care and understanding for people who care for others.','category':'Practical help','imageUrl':'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=1200&q=85'},
  ];

  final service = AdminContentService();
  int tab = 0;

  String get type => ['communities','resources','events','questions'][tab];
  String get storageType => tab == 3 ? 'resources' : type;
  String get singular => ['Community','Resource','Event','Suggested Question'][tab];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
          backgroundColor: cream,
          elevation: 0,
          foregroundColor: ink,
          title: Text('Village Admin', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: sage,
          foregroundColor: Colors.white,
          onPressed: _openEditor,
          icon: const Icon(Icons.add_rounded),
          label: Text('Add $singular'),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Run the Village without touching code.', style: GoogleFonts.inter(color: ink, fontSize: 15)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF243B2A), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminModerationScreen())),
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Moderate Posts & Review Reports'),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value:0,label:Text('Communities'),icon:Icon(Icons.groups_2_outlined)),
                    ButtonSegment(value:1,label:Text('Resources'),icon:Icon(Icons.menu_book_outlined)),
                    ButtonSegment(value:2,label:Text('Events'),icon:Icon(Icons.event_outlined)),
                    ButtonSegment(value:3,label:Text('Questions'),icon:Icon(Icons.lightbulb_outline_rounded)),
                  ],
                  selected:{tab},
                  onSelectionChanged:(value)=>setState(()=>tab=value.first),
                ),
              ),
            ]),
          ),
          Expanded(child:_content()),
        ]),
      );

  Widget _content() {
    if (!service.cloudReady) return const Center(child: Text('Firebase is not connected in this preview.'));
    return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      key: ValueKey(type),
      stream: service.watch(storageType),
      builder:(context,snapshot){
        if(snapshot.hasError) return Padding(padding:const EdgeInsets.all(24),child:Text('Admin content needs Firestore permission before it can load.\n\n${snapshot.error}'));
        if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
        if (tab == 0) return _communityList(snapshot.data!.docs);
        final docs=snapshot.data!.docs.where((doc){
          final isQuestion=(doc.data()['kind']??'').toString()=='question';
          return tab==3 ? isQuestion : tab==1 ? !isQuestion : true;
        }).toList();
        return _documentList(docs);
      },
    );
  }

  Widget _communityList(List<QueryDocumentSnapshot<Map<String,dynamic>>> docs) {
    final overrides = <String, QueryDocumentSnapshot<Map<String,dynamic>>>{};
    final custom = <QueryDocumentSnapshot<Map<String,dynamic>>>[];
    for (final doc in docs) {
      final builtin = (doc.data()['builtinId'] ?? '').toString();
      if (builtin.isEmpty) {
        custom.add(doc);
      } else {
        overrides[builtin] = doc;
      }
    }
    final items = <({String id, Map<String,dynamic> data, bool builtin})>[];
    for (final base in builtInCommunities) {
      final builtinId = base['id']!;
      final override = overrides[builtinId];
      items.add((
        id: override?.id ?? 'builtin_$builtinId',
        data: <String,dynamic>{...base, ...?override?.data(), 'builtinId': builtinId, 'published': true},
        builtin: true,
      ));
    }
    for (final doc in custom) {
      items.add((id: doc.id, data: doc.data(), builtin: false));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20,0,20,100),
      itemCount: items.length,
      separatorBuilder:(_,__)=>const SizedBox(height:12),
      itemBuilder:(_,index)=>_itemCard(items[index].id, items[index].data, builtin: items[index].builtin),
    );
  }

  Widget _documentList(List<QueryDocumentSnapshot<Map<String,dynamic>>> docs) {
    if(docs.isEmpty) {
      return Center(child:Padding(padding:const EdgeInsets.all(32),child:Column(mainAxisSize:MainAxisSize.min,children:[
        Icon(_tabIcon(),size:48,color:sage),
        const SizedBox(height:14),
        Text('No ${type.toLowerCase()} yet',style:GoogleFonts.playfairDisplay(fontSize:24,fontWeight:FontWeight.w700)),
        const SizedBox(height:8),
        Text('Tap “Add $singular” to create one.',textAlign:TextAlign.center),
      ])));
    }
    return ListView.separated(
      padding:const EdgeInsets.fromLTRB(20,0,20,100),
      itemCount:docs.length,
      separatorBuilder:(_,__)=>const SizedBox(height:12),
      itemBuilder:(_,i)=>_itemCard(docs[i].id, docs[i].data()),
    );
  }

  Widget _itemCard(String id, Map<String,dynamic> data, {bool builtin=false}) {
    final published=data['published']==true;
    final image=(data['imageUrl']??'').toString();
    return Card(
      elevation:0,
      color:Colors.white,
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side:BorderSide(color:ink.withValues(alpha:.08))),
      child:Padding(
        padding:const EdgeInsets.all(16),
        child:Row(children:[
          if(image.isNotEmpty) Padding(
            padding:const EdgeInsets.only(right:12),
            child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.network(image,width:64,height:64,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox(width:64,height:64,child:Icon(Icons.image_not_supported_outlined)))),
          ),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              Expanded(child:Text((data['title']??data['name']??data['question']??'Untitled').toString(),style:GoogleFonts.inter(fontWeight:FontWeight.w700,fontSize:16))),
              if (builtin) Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:sage.withValues(alpha:.08),borderRadius:BorderRadius.circular(99)),child:const Text('Built-in',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700))),
            ]),
            const SizedBox(height:5),
            Text((data['description']??data['summary']??data['community']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis),
            const SizedBox(height:10),
            Text(published?'Published':'Draft',style:TextStyle(color:published?sage:ink,fontWeight:FontWeight.w600)),
          ])),
          PopupMenuButton<String>(
            onSelected:(action){
              if(action=='edit') _openEditor(id:id,existing:data,isBuiltIn:builtin);
              if(action=='delete') _confirmDelete(id);
            },
            itemBuilder:(_)=>[
              const PopupMenuItem(value:'edit',child:Text('Edit')),
              if(!builtin) const PopupMenuItem(value:'delete',child:Text('Delete')),
            ],
          ),
        ]),
      ),
    );
  }

  IconData _tabIcon()=>switch(tab){0=>Icons.groups_2_outlined,1=>Icons.menu_book_outlined,2=>Icons.event_outlined,_=>Icons.lightbulb_outline_rounded};

  Future<void> _confirmDelete(String id) async {
    final itemType=singular;
    final ok=await showDialog<bool>(context:context,useRootNavigator:false,barrierDismissible:false,builder:(dialogContext)=>AlertDialog(
      title:Text('Delete $itemType?'),
      content:const Text('This cannot be undone.'),
      actions:[
        TextButton(onPressed:()=>Navigator.of(dialogContext).pop(false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.of(dialogContext).pop(true),child:const Text('Delete')),
      ],
    ));
    if(ok!=true)return;
    try{
      await service.delete(storageType,id);
      if(!mounted)return;
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content:Text('$itemType deleted.')));
    } on FirebaseException catch(error){
      if(!mounted)return;
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content:Text('Could not delete $itemType: ${error.message??error.code}')));
    }
  }

  Future<void> _openEditor({String? id,Map<String,dynamic>? existing,bool isBuiltIn=false}) async {
    final title=TextEditingController(text:(existing?['title']??existing?['name']??existing?['question']??'').toString());
    final description=TextEditingController(text:(existing?['description']??existing?['summary']??'').toString());
    final community=TextEditingController(text:(existing?['community']??'').toString());
    final category=TextEditingController(text:(existing?['category']??'').toString());
    final date=TextEditingController(text:(existing?['dateTimeLabel']??'').toString());
    final body=TextEditingController(text:(existing?['body']??'').toString());
    final helpState=TextEditingController(text:(existing?['state']??'').toString());
    final helpNeed=TextEditingController(text:(existing?['need']??'').toString());
    final helpUrl=TextEditingController(text:(existing?['url']??'').toString());
    final helpPhone=TextEditingController(text:(existing?['phone']??'').toString());
    final helpLabel=TextEditingController(text:(existing?['freeLabel']??'Free resource').toString());
    final helpVerified=TextEditingController(text:(existing?['verifiedAt']??'').toString());
    bool helpResource=existing?['helpResource']==true;
    bool published=isBuiltIn ? true : existing?['published']==true;
    await showModalBottomSheet<void>(
      context:context,
      isScrollControlled:true,
      backgroundColor:cream,
      builder:(sheetContext)=>StatefulBuilder(builder:(context,setSheetState)=>Padding(
        padding:EdgeInsets.fromLTRB(20,22,20,MediaQuery.of(context).viewInsets.bottom+24),
        child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Expanded(child:Text(id==null?'Add $singular':'Edit $singular',style:GoogleFonts.playfairDisplay(fontSize:27,fontWeight:FontWeight.w700))),
            IconButton(onPressed:()=>Navigator.pop(sheetContext),icon:const Icon(Icons.close)),
          ]),
          const SizedBox(height:8),
          _field(title,tab==0?'Community name':tab==3?'Suggested question':'$singular title'),
          if(tab!=3)_field(description,'Short description',lines:3),
          if(tab==0)_field(category,'Category'),
          if(tab!=0)_field(community,'Community / category'),
          if(tab==1)...[
            _field(body,'Resource content',lines:8),
            SwitchListTile(
              contentPadding:EdgeInsets.zero,
              title:const Text('Show in Find Help directory'),
              subtitle:const Text('Use this for food, rent, utility, health, or other assistance.'),
              value:helpResource,
              onChanged:(value)=>setSheetState(()=>helpResource=value),
            ),
            if(helpResource)...[
              _field(helpState,'State codes (example: FL, GA). Leave blank for nationwide'),
              _field(helpNeed,'Needs, separated by commas (example: Food, Rent & Housing)'),
              _field(helpUrl,'Website link'),
              _field(helpPhone,'Phone number'),
              _field(helpLabel,'Label (example: Free • Florida)'),
              _field(helpVerified,'Last verified (example: September 2026)'),
            ],
          ],
          if(tab==2)_field(date,'Date & time'),
          if(tab!=3) Padding(
            padding:const EdgeInsets.only(top:14),
            child:Container(
              padding:const EdgeInsets.all(12),
              decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14)),
              child:const Row(children:[
                Icon(Icons.image_outlined,color:sage),
                SizedBox(width:10),
                Expanded(child:Text('Photo uploads are paused until Firebase Storage is enabled. Existing covers will stay in place.')),
              ]),
            ),
          ),
          if(!isBuiltIn) SwitchListTile(
            contentPadding:EdgeInsets.zero,
            title:const Text('Publish now'),
            subtitle:const Text('Turn this off to save as a draft.'),
            value:published,
            onChanged:(value)=>setSheetState(()=>published=value),
          ),
          const SizedBox(height:12),
          SizedBox(width:double.infinity,child:FilledButton.icon(
            style:FilledButton.styleFrom(backgroundColor:sage,padding:const EdgeInsets.symmetric(vertical:16)),
            onPressed:()async{
              if(title.text.trim().isEmpty)return;
              final values=<String,dynamic>{
                if(tab==0)'name':title.text.trim(),
                if(tab==3)'question':title.text.trim(),
                if(tab!=0&&tab!=3)'title':title.text.trim(),
                if(tab!=3)'description':description.text.trim(),
                if(tab!=3)'imageUrl':(existing?['imageUrl']??'').toString(),
                'published':published,
                'sortOrder':existing?['sortOrder']??DateTime.now().millisecondsSinceEpoch,
                if(tab==0)'category':category.text.trim(),
                if(tab!=0)'community':community.text.trim(),
                if(tab==1)'body':body.text.trim(),
                if(tab==1)'helpResource':helpResource,
                if(tab==1&&helpResource)'state':helpState.text.trim(),
                if(tab==1&&helpResource)'need':helpNeed.text.trim(),
                if(tab==1&&helpResource)'url':helpUrl.text.trim(),
                if(tab==1&&helpResource)'phone':helpPhone.text.trim(),
                if(tab==1&&helpResource)'freeLabel':helpLabel.text.trim(),
                if(tab==1&&helpResource)'verifiedAt':helpVerified.text.trim(),
                if(tab==2)'dateTimeLabel':date.text.trim(),
                if(tab==3)'kind':'question',
                if(isBuiltIn)'builtinId':(existing?['builtinId']??'').toString(),
              };
              await service.save(type:storageType,id:id,data:values);
              if(sheetContext.mounted)Navigator.pop(sheetContext);
            },
            icon:const Icon(Icons.publish_outlined),
            label:Text(published?'Save & Publish':'Save Draft'),
          )),
        ])),
      )),
    );
  }

  Widget _field(TextEditingController controller,String label,{int lines=1})=>Padding(
    padding:const EdgeInsets.only(top:14),
    child:TextField(
      controller:controller,
      maxLines:lines,
      decoration:InputDecoration(
        labelText:label,
        filled:true,
        fillColor:Colors.white,
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none),
      ),
    ),
  );
}
