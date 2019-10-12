//
//  ViewController.m
//  c_python
//
//  Created by srplab on 12-7-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#include "vsopenapi.h"
#import <objc/runtime.h>

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

static class ClassOfSRPInterface *SRPInterface;

static VS_INT32 Add(void *Object,VS_INT32 x,VS_INT32 y)
{
    SRPInterface ->Print("Call From ios, %d,%d",x,y);
    return x + y;
}

@implementation ViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,   NSUserDomainMask, YES); 
    NSString *documentsDirectory = [paths objectAtIndex:0]; 
    
    const char* destDir = [documentsDirectory UTF8String];
    printf("%s\n",destDir);
    VS_BOOL Result = StarCore_Init((VS_CHAR *)destDir);
    
    NSString *respaths = [[NSBundle mainBundle] resourcePath];
    const VS_CHAR *res_cpath = [respaths UTF8String];
    VS_CHAR python_path[512];
    VS_CHAR python_home[512];
    sprintf(python_home,"%s/python",res_cpath);
    sprintf(python_path,"%s/python2.7.zip",res_cpath);
    VSCoreLib_InitPython((VS_CHAR*)python_home,(VS_CHAR *)python_path,NULL);
    
    VS_CORESIMPLECONTEXT Context;
    
    SRPInterface = VSCoreLib_InitSimple(&Context,(VS_CHAR*)"test",(VS_CHAR*)"123",0,0,MsgCallBack,0,NULL);
    
    //Context.VSControlInterface -> SetScriptInterface("python","","-S -d");
    VS_CHAR pyBuf[512];
    sprintf(pyBuf,"print(\"hello from python\")");
    SRPInterface ->DoBuffer((VS_CHAR*)"python",(VS_CHAR*)pyBuf,strlen(pyBuf),(VS_CHAR*)"", NULL, NULL, VS_FALSE);  
    
    sprintf(pyBuf,"SrvGroup = libstarpy._GetSrvGroup()\n");
    strcat(pyBuf,"Service = SrvGroup._GetService(\"\",\"\")\n");
    strcat(pyBuf,"Obj=Service._New(\"TestClass\");\n");
    strcat(pyBuf,"def Obj_Add(self,x,y) :\n");
    strcat(pyBuf,"  cobj=self._Service.TestClassC._New();\n");
    strcat(pyBuf,"  print(cobj.Add(x,y))\n");
    strcat(pyBuf,"  cobj._Free()\n");
    strcat(pyBuf,"  return x+y;\n");
    strcat(pyBuf,"Obj.Add=Obj_Add\n");
    
    SRPInterface ->CheckPassword(VS_FALSE);
    SRPInterface ->DoBuffer((VS_CHAR*)"python",pyBuf,strlen(pyBuf),(VS_CHAR*)"", NULL, NULL, VS_FALSE);  
    
    void *AtomicClass = SRPInterface ->CreateAtomicObjectSimple((VS_CHAR*)"TestItem",(VS_CHAR*)"TestClassC",NULL,NULL,NULL);
    SRPInterface ->CreateAtomicFunctionSimpleEx(AtomicClass,(VS_CHAR*)"Add",(VS_CHAR*)"VS_INT32 Add(VS_INT32 x,VS_INT32 y);",(void *)Add,NULL);
    
    void *Class,*Object;
	Class = SRPInterface ->GetObjectEx(NULL,(VS_CHAR*)"TestClass");
	Object = SRPInterface ->MallocObjectL( SRPInterface->GetIDEx(Class),0,NULL);
	printf("Call Function Ret = %lu\n",SRPInterface ->ScriptCall(Object,NULL,(VS_CHAR*)"Add",(VS_CHAR*)"(ii)i",12,34));
   
    /*---call py raw function---*/
    sprintf(pyBuf,"def RawAdd(x,y) :\n");
    strcat(pyBuf,"  print(\"call raw function, 你好\")\n");
    strcat(pyBuf,"  return x+y;\n");
    
    SRPInterface ->DoBuffer((VS_CHAR*)"python",pyBuf,strlen(pyBuf),(VS_CHAR*)"", NULL, NULL, VS_FALSE);
    class ClassOfBasicSRPInterface *BasicSRPInterface;
    BasicSRPInterface = SRPInterface ->GetBasicInterface(); 
    BasicSRPInterface ->InitRaw((VS_CHAR*)"python",SRPInterface);
    void *python = SRPInterface ->ImportRawContext((VS_CHAR*)"python",(VS_CHAR*)"",false,NULL);
    printf("Call raw python add function = %d\n",(VS_INT32)SRPInterface->ScriptCall(python,NULL,(VS_CHAR*)"RawAdd",(VS_CHAR*)"(ii)i",234,567));
    
    printf("%s\n",BasicSRPInterface->GetCorePath());
    printf("%s\n",BasicSRPInterface->GetUserPath());    
    printf("%s\n",BasicSRPInterface->GetLocalIP());
    
    printf("%s\n",Context.VSControlInterface->GetLocale());
    
    char FileBuf[256];
    
    void *CClass = SRPInterface -> MallocObjectL(NULL,0,NULL);
    SRPInterface -> SetName( CClass, "CClass");
    SRPInterface -> RegLuaFunc( CClass, NULL, (void*)CClass_Obj_ScriptCallBack, (VS_UWORD)0 );
    SRPInterface -> RegLuaFuncFilter(CClass,CClass_Obj_LuaFuncFilter,(VS_UWORD)0);
    SRPInterface -> ScriptSetObject(python,"CClass",VSTYPE_OBJPTR,(VS_UWORD)CClass);
    
    sprintf(FileBuf,"%s/test_call.py",res_cpath);
    SRPInterface->DoFile("python", FileBuf, NULL,NULL,VS_FALSE);
    
    //--------------------------------------------------------
    //---test call NSObject
    Star_ObjectCBridge_Init(SRPInterface,NULL,NULL);
    /*---need include --#import <objc/runtime.h>-*/
    SRPInterface -> ScriptSetObject(python,"CClass",VSTYPE_OBJPTR,(VS_UWORD)_FromObjectC(objc_getClass("TestSRPClass")));
    sprintf(FileBuf,"%s/test_callnsobject.py",res_cpath);
    SRPInterface->DoFile("python", FileBuf, NULL,NULL,VS_FALSE);
    
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

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
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
