
/******************************************************************************
    * Copyright (C) 2012 SatheeshJM.  All rights reserved.
    *
    * Permission is hereby granted, free of charge, to any person obtaining
    * a copy of this software and associated documentation files (the
    * "Software"), to deal in the Software without restriction, including
    * without limitation the rights to use, copy, modify, merge, publish,
    * distribute, sublicense, and/or sell copies of the Software, and to
    * permit persons to whom the Software is furnished to do so, subject to
    * the following conditions:
    *
    * The above copyright notice and this permission notice shall be
    * included in all copies or substantial portions of the Software.
    *
    * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ******************************************************************************/
	
/*

-----USAGE------

require "notifications";

notifications.scheduleLocalNotification
{
alertBody = "Hello Gideros!!",
hasAction = true,
alertAction = "Check It Out!",
badge = 12,
timeInterval = {seconds =5,minutes=1,hours=1,days=1}, 	--Notification will be fired after the specified interval
--time = "2012-06-05 20:42:32 +0530",					--Notification will be fired AT the specified time
}

-----USAGE------

*/
	

#include "gideros.h"



static int stackdump(lua_State* l)
{
    // Thanks, Caroline Begbie
    NSLog(@"stackdump");
    
    int top = lua_gettop(l);
    //Returns index of the top most element. And hence, it is the number of Stack elements

    
    for (int i = 1; i <= top; i++)
    {  
        printf("  ");
        int t = lua_type(l, i);
        switch (t) {
            case LUA_TSTRING:  //strings
                printf("string: '%s'\n", lua_tostring(l, i));
                break;
            case LUA_TBOOLEAN:  //booleans
                printf("boolean %s\n",lua_toboolean(l, i) ? "true" : "false");
                break;
            case LUA_TNUMBER:  //numbers
                printf("number: %g\n", lua_tonumber(l, i));
                break;
            default:  //other values
                printf("%s\n", lua_typename(l, t));
                break;
        }
    }
    printf("\n");
    return 0;
}









NSMutableDictionary* luaTableToDictionary(lua_State* L,int stack_index)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    //  STACK  { Table }
    
    lua_pushnil(L);
    //  STACK  { Table      Nil     }
    

    while (lua_next(L, stack_index) != 0) {
        
        //  STACK  { Table      key     Value   }
        
        
        id key = nil;
        switch(lua_type(L,-2))  {
            case LUA_TNUMBER: {
                int value = lua_tonumber(L, -2);
                NSNumber *number = [NSNumber numberWithInt:value];
                key = number;
                break;
            }
            case LUA_TSTRING: {
                NSString *value = [NSString stringWithUTF8String:luaL_checkstring(L, -2)];
                key = value;
                break;
            }    
                
        }
        
        
        id value = nil;
        switch (lua_type(L, -1)) {
            case LUA_TNUMBER: {
                int val = lua_tonumber(L, -1);
                NSNumber *number = [NSNumber numberWithInt:val];
                value = number;
                break;
            }
            case LUA_TBOOLEAN: {
                int val = lua_toboolean(L, -1);
                NSNumber *number = [NSNumber numberWithBool:val];
                value = number;
                break;
            }
            case LUA_TSTRING: {
                NSString *val = [NSString stringWithUTF8String:luaL_checkstring(L, -1)];
                value = val;
                break;
            }
            case LUA_TTABLE: {
                NSMutableDictionary *dict = luaTableToDictionary(L,stack_index+2);
                value = dict; 
                break;
            }
        }
        [dict setObject:value forKey:key];
        lua_pop(L, 1);

    }
    

    return dict;
}






static int scheduleLocalNotification(lua_State *L)
{
    
    NSMutableDictionary *dict = luaTableToDictionary(L,1);

    id alertBody = [dict objectForKey:@"alertBody"];
    id alertAction = [dict objectForKey:@"alertAction"];
    id time = [dict objectForKey:@"time"];
    BOOL hasAction = [[dict objectForKey:@"hasAction"] boolValue ];
    NSInteger badge = [[dict objectForKey:@"badge"] integerValue];
    NSMutableDictionary* timeInterval = [dict objectForKey:@"timeInterval"];
    
    
    
    NSDate* date;
    if (time)
    {
        date = [[NSDate alloc] initWithString:time];
    }
    else    
    {
        NSDate *currentDate = [NSDate date];
        NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setSecond:[[timeInterval objectForKey:@"seconds"] integerValue]] ;
        [comps setMinute:[[timeInterval objectForKey:@"minutes"] integerValue]]; 
        [comps setHour:  [[timeInterval objectForKey:@"hours"] integerValue]];
        [comps setDay:   [[timeInterval objectForKey:@"days"] integerValue]];

        date = [calendar dateByAddingComponents:comps toDate:currentDate  options:0];
        [comps release];
    }
    
    
    
    //ACTUAL NOTIFICATION
    
    
    UILocalNotification* notify = [[[UILocalNotification alloc]init]autorelease];
    
    notify.fireDate = date;
    notify.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@", nil),alertBody];
    notify.hasAction = hasAction;
    notify.alertAction = NSLocalizedString(alertAction, nil);
    notify.applicationIconBadgeNumber = badge;
    notify.soundName = UILocalNotificationDefaultSoundName;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notify];
    
    return 0;
}



static int loader(lua_State *L)
{
    
    const luaL_Reg functionlist[] = {
        {"scheduleLocalNotification", scheduleLocalNotification},
        {NULL, NULL},
    };
    luaL_register(L, "notifications", functionlist);
    
    
    
  

    return 0;
}





static void g_initializePlugin(lua_State* L)
{
    lua_getglobal(L, "package");
    //STACK :   { _G.package}
    
    lua_getfield(L, -1, "preload");
    //STACK :   {_G.package.preload     _G.package}
    
    lua_pushcfunction(L, loader);
    //STACK :   {loader     _G.package.preload     _G.package}
    
    lua_setfield(L, -2, "notifications");
    //STACK :   { _G.package.preload     _G.package}
    
    lua_pop(L, 2);   
    
}

static void g_deinitializePlugin(lua_State *L) 
{   
}

REGISTER_PLUGIN("notifications", "1.0")