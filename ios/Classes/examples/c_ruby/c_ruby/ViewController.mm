//
//  ViewController.m
//  c_ruby
//
//  Created by srplab on 15/5/10.
//  Copyright (c) 2015年 srplab. All rights reserved.
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

extern "C" void ruby_init_ext(const char *name, void (*init)(void));
extern "C" void Init_socket();

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,   NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    const char* destDir = [documentsDirectory UTF8String];
    VS_BOOL Result = StarCore_Init((VS_CHAR *)destDir);
    
    VSCoreLib_InitRuby();
    
    VS_CORESIMPLECONTEXT Context;
    
    SRPInterface = VSCoreLib_InitSimple(&Context,"test","123",0,0,MsgCallBack,0,NULL);
    SRPInterface ->CheckPassword(VS_FALSE);
    
    //---set ruby search path
    NSString *respaths = [[NSBundle mainBundle] resourcePath];
    const VS_CHAR *res_cpath = [respaths UTF8String];
    
    class ClassOfBasicSRPInterface *BasicSRPInterface;
    
    BasicSRPInterface = SRPInterface ->GetBasicInterface();
    BasicSRPInterface ->InitRaw("ruby", SRPInterface);
    
    void *ruby = SRPInterface -> ImportRawContext("ruby", "", VS_FALSE, "");
    void *LOAD_PATH = (void *)SRPInterface -> ScriptGetObject(ruby,"LOAD_PATH", NULL);
    SRPInterface->ScriptCall(LOAD_PATH,NULL, "unshift", "(s)",res_cpath);
    
    VS_CHAR rbBuf[512];
    //sprintf(rbBuf,"puts(\"hello from ruby\")");
    sprintf(rbBuf,"puts($starruby)");
    SRPInterface ->DoBuffer((VS_CHAR*)"ruby",(VS_CHAR*)rbBuf,strlen(rbBuf),(VS_CHAR*)"", NULL, NULL, VS_FALSE);
    

    VS_CHAR filename[512];
    sprintf(filename,"%s/test.rb",res_cpath);
    SRPInterface ->DoFile("ruby",filename,NULL,NULL,VS_FALSE);
    
    void *CClass = SRPInterface -> MallocObjectL(NULL,0,NULL);
    SRPInterface -> SetName( CClass, "CClass");
    SRPInterface -> RegLuaFunc( CClass, NULL, (void*)CClass_Obj_ScriptCallBack, (VS_UWORD)0 );
    SRPInterface -> RegLuaFuncFilter(CClass,CClass_Obj_LuaFuncFilter,(VS_UWORD)0);
    SRPInterface -> ScriptSetObject(ruby,"CClass",VSTYPE_OBJPTR,(VS_UWORD)CClass);
    
    sprintf(filename,"%s/test_call.rb",res_cpath);
    SRPInterface->DoFile("ruby", filename, NULL,NULL,VS_FALSE);
    
    //--------------------------------------------------------
    //---test call NSObject
    Star_ObjectCBridge_Init(SRPInterface,NULL,NULL);
    /*---need include --#import <objc/runtime.h>-*/
    SRPInterface -> ScriptSetObject(ruby,"$CClass",VSTYPE_OBJPTR,(VS_UWORD)_FromObjectC(objc_getClass("TestSRPClass")));
    sprintf(filename,"%s/test_callnsobject.rb",res_cpath);
    SRPInterface->DoFile("ruby", filename, NULL,NULL,VS_FALSE);
    
    int ObjectNum = BasicSRPInterface ->GetObjectNum();
    BasicSRPInterface ->Release();
    
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
    if( strcmp(FuncName,"SetPythonObject") == 0 )
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
    }else if( strcmp(ScriptName,"SetPythonObject") == 0 ){
        void *raw = SRPInterface->LuaToObject(2);
        printf("%s\n",(char *)SRPInterface ->GetRawContextType(raw,NULL));
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

-(id)usingPointer:(NSObject *)which
{
    return nil;
}
@end


