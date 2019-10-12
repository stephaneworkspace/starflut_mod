//
//  ViewController.m
//  c_lua
//
//  Created by srplab on 14-9-30.
//  Copyright (c) 2014年 srplab. All rights reserved.
//

#import "ViewController.h"
#include "vsopenapi.h"
#import <objc/runtime.h>

static class ClassOfSRPInterface *SRPInterface;

static VS_UWORD MsgCallBack( VS_ULONG ServiceGroupID, VS_ULONG uMsg, VS_UWORD wParam, VS_UWORD lParam, VS_BOOL *IsProcessed, VS_UWORD Para )
{
    switch( uMsg ){
        case MSG_VSDISPMSG :
        case MSG_VSDISPLUAMSG :
            printf("[core]%s\n",(VS_CHAR *)wParam);
            break;
        case MSG_DISPMSG :
        case MSG_DISPLUAMSG :
            printf("%s\n",(VS_CHAR *)wParam);
            break;
    }
    return 0;
}

static VS_INT32 Add(void *Object,VS_INT32 x,VS_INT32 y)
{
    SRPInterface ->Print("Call From ios, %d,%d",x,y);
    return x + y;
}


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,   NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    const char* destDir = [documentsDirectory UTF8String];
    
    NSString *respaths = [[NSBundle mainBundle] resourcePath];
    const VS_CHAR *res_cpath = [respaths UTF8String];
    
    VS_BOOL Result = StarCore_Init((VS_CHAR *)destDir);
    
    VS_CORESIMPLECONTEXT Context;
    
    SRPInterface = VSCoreLib_InitSimple(&Context,"test","123",0,0,MsgCallBack,0,NULL);
    
    VS_CHAR LuaBuf[512];
    sprintf(LuaBuf,"print(\"hello from lua\")");
    SRPInterface ->DoBuffer("lua",LuaBuf,strlen(LuaBuf),"", NULL, NULL, VS_FALSE);
    
    sprintf(LuaBuf,"SrvGroup = libstarcore._GetSrvGroup()\n");
    strcat(LuaBuf,"Service = SrvGroup:_GetService(\"\",\"\")\n");
    strcat(LuaBuf,"Obj=Service:_New(\"TestClass\");\n");
    strcat(LuaBuf,"function Obj:Add(x,y)\n");
    strcat(LuaBuf,"  local cobj=self._Service.TestClassC:_New();\n");
    strcat(LuaBuf,"  print(cobj:Add(x,y))\n");
    strcat(LuaBuf,"  cobj:_Free()\n");
    strcat(LuaBuf,"  return x+y;\n");
    strcat(LuaBuf,"end\n");
    
    SRPInterface ->CheckPassword(VS_FALSE);
    SRPInterface ->DoBuffer((VS_CHAR*)"lua",LuaBuf,strlen(LuaBuf),(VS_CHAR*)"", NULL, NULL, VS_FALSE);
    
    void *AtomicClass = SRPInterface ->CreateAtomicObjectSimple((VS_CHAR*)"TestItem",(VS_CHAR*)"TestClassC",NULL,NULL,NULL);
    SRPInterface ->CreateAtomicFunctionSimpleEx(AtomicClass,(VS_CHAR*)"Add",(VS_CHAR*)"VS_INT32 Add(VS_INT32 x,VS_INT32 y);",(void *)Add,NULL);
    
    void *Class,*Object;
    Class = SRPInterface ->GetObjectEx(NULL,(VS_CHAR*)"TestClass");
    Object = SRPInterface ->MallocObjectL( SRPInterface->GetIDEx(Class),0,NULL);
    printf("Call Function Ret = %lu\n",SRPInterface ->ScriptCall(Object,NULL,(VS_CHAR*)"Add",(VS_CHAR*)"(ii)i",12,34));
    
    /*---call lua raw function---*/
    sprintf(LuaBuf,"function RawAdd(x,y)\n");
    strcat(LuaBuf,"  print(\"call raw function\")\n");
    strcat(LuaBuf,"  return x+y;\n");
    strcat(LuaBuf,"end\n");
    
    SRPInterface ->DoBuffer((VS_CHAR*)"lua",LuaBuf,strlen(LuaBuf),(VS_CHAR*)"", NULL, NULL, VS_FALSE);
    class ClassOfBasicSRPInterface *BasicSRPInterface;
    BasicSRPInterface = SRPInterface ->GetBasicInterface();
    BasicSRPInterface ->InitRaw("lua",SRPInterface);
    void *lua = SRPInterface ->ImportRawContext("lua","",false,NULL);
    printf("Call raw lua add function = %d\n",(VS_INT32)SRPInterface->ScriptCall(lua,NULL,"RawAdd","(ii)i",234,567));
    
    char *LocalIP = BasicSRPInterface ->GetLocalIP();
    SOCKADDR_IN LocalIP1[64];
    int Number = BasicSRPInterface->GetLocalIPEx(LocalIP1,64);
    
    void *CClass = SRPInterface -> MallocObjectL(NULL,0,NULL);
    SRPInterface -> SetName( CClass, "CClass");
    SRPInterface -> RegLuaFunc( CClass, NULL, (void*)CClass_Obj_ScriptCallBack, (VS_UWORD)0 );
    SRPInterface -> RegLuaFuncFilter(CClass,CClass_Obj_LuaFuncFilter,(VS_UWORD)0);
    SRPInterface -> ScriptSetObject(lua,"CClass",VSTYPE_OBJPTR,(VS_UWORD)CClass);
    
    char FileBuf[256];
    sprintf(FileBuf,"%s/test_call.lua",res_cpath);
    SRPInterface->DoFile("lua", FileBuf, NULL,NULL,VS_FALSE);
    
    //--------------------------------------------------------
    //---test call NSObject
    Star_ObjectCBridge_Init(SRPInterface,NULL,NULL);
    /*---need include --#import <objc/runtime.h>-*/
    SRPInterface -> ScriptSetObject(lua,"CClass",VSTYPE_OBJPTR,(VS_UWORD)_FromObjectC(objc_getClass("TestSRPClass")));
    sprintf(FileBuf,"%s/test_callnsobject.lua",res_cpath);
    SRPInterface->DoFile("lua", FileBuf, NULL,NULL,VS_FALSE);
    
    SRPInterface -> Release();
    VSCoreLib_TermSimple(&Context);
}

static VS_BOOL SRPAPI CClass_Obj_LuaFuncFilter(void *Object,void *ForWhichObject,VS_CHAR *FuncName,VS_UWORD Para)
{
    if( strcmp(FuncName,"getinfo") == 0 )
        return VS_TRUE;
    if( strcmp(FuncName,"_StarCall") == 0 )
        return VS_TRUE;
    if( strcmp(FuncName,"callback") == 0 )
        return VS_TRUE;
    if( strcmp(FuncName,"SetLuaObject") == 0 )
        return VS_TRUE;
    return VS_FALSE;
}
static VS_INT32 CClass_Obj_ScriptCallBack( void *L )
{
    struct StructOfCClassLocalBuf  *CClassLocalBuf;
    void *Object;
    VS_CHAR *ScriptName;
    
    ScriptName = SRPInterface -> LuaToString( SRPInterface -> LuaUpValueIndex(3) );
    Object = SRPInterface -> LuaToObject(1);
    /*first input parameter is started at index 2 */
    CClassLocalBuf = (struct StructOfCClassLocalBuf *)SRPInterface -> GetPrivateBuf( Object, SRPInterface -> GetLayer(Object),0, NULL );
    if( strcmp(ScriptName,"getinfo") == 0 ){
        SRPInterface ->LuaPushString("this module is create by star_module");
        return 1;
    }else if( strcmp(ScriptName,"_StarCall") == 0 ){
        VS_CHAR *Info = SRPInterface ->LuaToString(2);
        printf("%s\n",Info);
        void *Inst = SRPInterface ->IMallocObjectL(SRPInterface->GetIDEx(Object),NULL);
        SRPInterface ->LuaPushObject(Inst);
        return 1;
    }else if( strcmp(ScriptName,"callback") == 0 ){
        if( SRPInterface ->LuaType(2) == VSLUATYPE_NUMBER ){
            double d = SRPInterface ->LuaToNumber(2);
            printf("%f\n",d);
        }else{
            printf("%s\n",SRPInterface->LuaToString(2));
        }
        return 0;
    }else if( strcmp(ScriptName,"SetLuaObject") == 0 ){
        VS_PARAPKGPTR Para = SRPInterface->LuaToParaPkg(2);
        printf("%s    %s\n",Para->GetStr(0),Para->GetStr(1));
    }
    return 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

@implementation TestSRPClass

@synthesize name;
@synthesize DoubleValue;
@synthesize IntValue;

+(NSObject*)initTestSRPClass:(NSString *)initName
{
    TestSRPClass *obj = [[TestSRPClass alloc]init];
    obj->name = initName;
    return obj;
}

-(id)usingPointer:(NSObject *)CleObject
{
    return nil;
}
@end
