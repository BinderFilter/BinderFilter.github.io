---
layout: default
title: How Xposed Works
permalink: /xposed/
---
# Fantastic hooks and Where to find them (Xposed edition)

## An introduction to Xposed

As you know, most of the Android OS is open source. The proprietary parts are those that are vendor specific, flashed onto the /vendor
partition of your filesystem. Being open source means that Android is fully customizable. You can download, modify, compile and run Android from source by following the guide [here](https://source.android.com/setup/downloading).
This essentially gives you limitless power to modify how your Android phone works.

Android like any other OS makes trade-offs in the kernel and framework level to cater to the average smartphone user.
There are a number of developers who have modified and recompiled Android from source in order to unlock new capabilities otherwise
disabled in the "Stock" Android OS. These are called "custom ROMs". One such option is LineageOS which allows for CPU overclocking and
some really funky themes otherwise not possible in the "stock" Android ecosystem.

For many though, rebuilding Android from the scratch is too painful (it really is..) while custom ROMs either do not accomplish
what they want or do a lot more than they are comfortable with.

Xposed is a middleground for such people. You can use Xposed on a rooted "stock" Android to achieve effectively the same effects custom ROMs provide.
Xposed is a "dynamic" hooking framework that allows developers to replace any method in any class (framework or a custom application).
You can change parameters for the method call, modify the return value or skip the call to the method completely. People have used this for various
applications in the past, such as to get around Twitter's character limit.

As an example, if you want to change what the default Android clock displays, you can:

1. Go through the source code of the status bar clock [here](https://android.googlesource.com/platform/frameworks/base/+/android-6.0.1_r25/packages/SystemUI/src/com/android/systemui/statusbar/policy/Clock.java)
2. Notice that the method updateClock() is called every time the clock is to be updated, and override the method using
3. Xposed's "findAndHookMethod" utility, which we will explore later on in this tutorial.

Some more motivation because little motivation is more harmful than no motivation :)

#### Irritated with all the background services that consume most of your battery charge and want to choose which ones to enable?##

There is an Xposed module for [that](https://www.androidauthority.com/improve-battery-life-xposed-amplify-greenify-668844/). It deals with power consuming
background services in a stricter way than the Android OS does.

#### Want to change what happens when you press the Power buttton ?##
There is an Xposed module for that (Advanced Power Menu+ (APM+)).

#### Do you want to cheat on Pokemon Go and feed the app made up locations ?##
There is an Xposed module for that - XPrivacy ( which actually does a lot [more](https://github.com/M66B/XPrivacy) ).

#### Want to hook libbinder.so to inter-mediate most IPC on your Android phone ?
You can't write an Xposed module for that. Essentially, Xposed relies on the ability to move the hooked method to another location, adding a proxy to the original method, which calls
the hook, which eventually calls the original method at its new location. It cannot move methods in SYSTEM shared libraries this way .
If you want to hook function calls in SYSTEM shared libraries such as libbinder.so though check out [Frida](https://www.frida.re/docs/frida-trace/) trace.
Note that you can still hook non-system shared libraries loaded by your module with Xposed.

You can browse existing Xposed repos [here](http://repo.xposed.info/module-overview) .

It is quite easy to write your own Xposed module. See the next section to learn how to do so.

### Xposed - How to install

To work with Xposed, a pre-requisite is a rooted phone.
For instructions on how to root your phone, refer to

To obtain the Xposed framework in order to flash it onto your phone, download the zip file [here](http://dl-xda.xposed.info/framework/sdk25/arm64)

The step by step guide to installing Xposed is [here](https://forum.xda-developers.com/showthread.php?t=3034811) and
[here](https://www.howtogeek.com/164634/forget-flashing-custom-roms-use-the-xposed-framework-to-tweak-your-android/) (More newbie friendly)

When you are ready to create your own Xposed module, refer to the [Development Tutorial](https://github.com/rovo89/XposedBridge/wiki/Development-tutorial)

The example [project](https://github.com/rovo89/XposedExamples/tree/master/RedClock) linked in the above tutorial is way outdated
and Android Studio is not able to recognize it as a valid project.
Clone Emarty's [project](https://github.com/emartynov/XposedExamples) instead and start working from there!.

You can refer to the Xposed framework [API](http://api.xposed.info/reference/packages.html) while building your module.

Reading the source is quite illuminating as well.

### Xposed initialization- a high level overview

There is a process that is called "Zygote". This is the heart of the Android runtime.
Every application is started as a fork of it. This process is started by an init script when the phone is booted.
The process start is done with /system/bin/app_process, which Xposed replaces with its own extended app_process.

Xposed's implementation of [app_process](https://github.com/rovo89/Xposed/blob/master/app_main.cpp#L256) calls

```java
xposed::initialize(zygote, startSystemServer, className, argc, argv);
```
which adds XposedBridge.jar to the CLASSPATH and loads the modules declared at /data/data/de.robv.android.xposed.installer/conf/modules.list

All the XposedInstaller does is extract and load the classes found in the given module apk as JAR and add the path to it in this list.
Once you install an Xposed module you need to do a soft reboot before using the module. The soft reboot kills the Zygote.

Any Xposed module implements one or more of the following interfaces:
1. IXposedHookInitPackageResources -  To hook when resources for an app are being initialized
2. IXposedHookLoadPackage - To hook when a package is being loaded
3. IXposedHookZygoteInit - To hook when the Zygote is being initialized.

Our example implements IXposedHookLoadPackage and waits for the package "com.android.systemui" to load.
Once loaded it hooks the method "updateClock".

# How Xposed adds hooks to any method

In the earlier motivating example, I mentioned that once you identify the method you want to hook into, you can use "findAndHookMethod" to add
callbacks before and after the method is called.

## The API of findAndHookMethod

The hooking of the method updateClock() looks like this:

```java
findAndHookMethod("com.android.systemui.statusbar.policy.Clock", classLoader, "updateClock", new XC_MethodHook() {
			@Override
			protected void afterHookedMethod(MethodHookParam param) throws Throwable {
				TextView tv = (TextView) param.thisObject;
				String text = tv.getText().toString();
				tv.setText("CS65/165 rocks :)");
				tv.setTextColor(Color.GREEN);
			}
});
```

We gave findAndHookMethod 4 params:

- className - for the method we want to hook.
- The classLoader is unique per package or application and is used internally to obtain the  class represented by className above.
- The actual method name.
- A method hook class in which we can override:
  - beforeHookedMethod which is called before updateClock() is called. We can use to modify parameters to updateClock(), skip the call to updateClock() and execute arbitraty code, and so on.
  - afterHookedMethod which is called after updateClock() is called. It operates similarly.


## findAndHookMethod explored


### Part one - reaching XposedBridge

The findAndHookMethod implementation just calls the overridden implementation of findAndHookMethod after obtatining the class corresponding to the className string.
This is done using Class.forName, without initializing the Class ( [cf](https://stackoverflow.com/a/39768345) ), just loading the class into memory and
returning a reference to the class.

The class so obtained, along with the methodName and callback is passed in as parameter [here](https://github.com/rovo89/XposedBridge/blob/a535c02ed9dfd53683cc0274d9f95bcb6ffb9f79/app/src/main/java/de/robv/android/xposed/XposedHelpers.java#L180)

```java
public static XC_MethodHook.Unhook findAndHookMethod(Class<?> clazz, String methodName, Object... parameterTypesAndCallback) {
		if (parameterTypesAndCallback.length == 0 || !(parameterTypesAndCallback[parameterTypesAndCallback.length-1] instanceof XC_MethodHook))
			throw new IllegalArgumentException("no callback defined");

		XC_MethodHook callback = (XC_MethodHook) parameterTypesAndCallback[parameterTypesAndCallback.length-1];
		Method m = findMethodExact(clazz, methodName, getParameterClasses(clazz.getClassLoader(), parameterTypesAndCallback));

		return XposedBridge.hookMethod(m, callback);
}
```

Using the awesome power of java reflection ( for an interesting read [see](https://stackoverflow.com/questions/16635025/dosent-reflection-api-break-the-very-purpose-of-data-encapsulation) )
we obtain the "java.reflect.Method" object corresponding to the method we want to hook by calling findMethodExact 

Next we call XposedBridge.hookMethod(m, callback) where m is the reflect method corresponding to the method we want to hook and
callback is the callback hook we specified in our Xposed module.

### Part two - XposedBridge

hookMethod(Member hookMethod, XC_MethodHook callback) first appends our callback for updateClock() into a list of callbacks for updateClock().
There may be multiple modules hooking the same methods for different reasons and so Xposed keeps a Map<method,callbacks> object to keep track of the
callbacks to be executed when a hooked method is called.

After other bookkeeping logic, hookMethodNative() is called with the given Method m, callback list and additional information.
hookMethodNative is declared as a 'native' method in XposedBridge which indicates to ART that the implementation of the method can be found elsewhere.

### Detour - How native methods are registered with JNI by Xposed

onVmCreated in app_main is the implementation of the virtual method defined in the Android Runtime. 
It is called once when the runtime for the application is ready.
It in turn calls [xposed::onVmCreated](https://github.com/rovo89/Xposed/blob/c851ed911c87b7dc48bb33d019e835dc1066b886/app_main.cpp#L86) which:

1. Determines if the runtime is Dalvik or ART.

2. loads Xposed's modifications of ART/Dalvik into process memory with dlopen.

3. Calls xposedInitLib from the just loaded shared library which in turn serves the purpose of setting
   the xposed::onVmCreated callback to onVmCreatedCommon in [libxposed_common.cpp](https://github.com/rovo89/Xposed/blob/4b9a7a612c180dc47019724a8e66e79f4f5e7e83/libxposed_common.cpp#L132) .
   
4. Calls [xposed:onVmCreated](https://github.com/rovo89/Xposed/blob/0307d5cd9612a9ec18ae8ed8b58e25d4ea3199d5/xposed.cpp#L417) (now mapped to onVmCreatedCommon)

[onVmCreatedCommon(JNIEnv *env)*](https://github.com/rovo89/Xposed/blob/4b9a7a612c180dc47019724a8e66e79f4f5e7e83/libxposed_common.cpp#L132) does a lot of heavy lifting after being called in xposed::onVmCreated at last.

It:

a) Loads the XposedBridge JAR which had earlier been added to the CLASSPATH and stored the loaded class in the classXposedBridge variable.

b) Calls register_natives_XposedBridge  which takes all the JNI methods used and defined by Xposed,
1. reinterpret_cast'ing the method names such as hookMethodNative(...) becomes XposedBridge_hookMethodNative(...)

2. Calls JNIEnv->RegisterNatives(clazz, methods, NELEM(methods)) where the clazz is XposedBridge (which calls these native methods such as hookMethodNative) and methods is the list of the JNI methods. According to JNI documentation, [RegisterNatives](https://docs.oracle.com/javase/7/docs/technotes/guides/jni/spec/functions.html#wp5838) "Registers native methods with the class specified by the clazz argument"

c) Uses the JNI Environment to get a handle to the "handleHookedMethod" in XposedBridge.
```
methodXposedBridgeHandleHookedMethod = env->GetStaticMethodID(classXposedBridge, "handleHookedMethod",
"(Ljava/lang/reflect/Member;ILjava/lang/Object;Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;");
```

GetStaticMethodID gives us a methodID token for "handleHookedMethod" which we will use to call into Java XposedBridge [code](https://docs.oracle.com/javase/7/docs/technotes/guides/jni/spec/functions.html).

d) Calls the runtime-specific onVmCreated [callback](https://github.com/rovo89/Xposed/blob/4b9a7a612c180dc47019724a8e66e79f4f5e7e83/libxposed_common.cpp#L137) which looks like:

```c
   bool onVmCreated(JNIEnv*) {
	     ArtMethod::xposed_callback_class = classXposedBridge;
	     ArtMethod::xposed_callback_method = methodXposedBridgeHandleHookedMethod;
	     return true;
}	     
```

Note that the xposed_callback_method set on ArtMethod is the same as the one initialized in the previous step.

d) returns.

### Back to the point

Recalling  XposedBridge's [hookMethod](https://github.com/rovo89/XposedBridge/blob/art/app/src/main/java/de/robv/android/xposed/XposedBridge.java#L244) it eventually calls hookMethodNative in JNI.

hookMethodNative(hookMethod, declaringClass, slot, additionalInfo) takes:

1. Reflect instance of method to be hooked.

2. The class that declared the method, obtained with Method.getDeclaringClass().

3. slot - gets the "slot" field from the hooked method using reflection.

4. additionalInfo - is initialized as
```java
private AdditionalHookInfo(CopyOnWriteSortedSet<XC_MethodHook> callbacks, Class<?>[] parameterTypes, Class<?> returnType) {
			this.callbacks = callbacks;
			this.parameterTypes = parameterTypes;
			this.returnType = returnType;
}
```

 and contains the callbacks that are to be called for the method.

We now know from the "detour" that the actual implementation of hookMethodNative is XposedBridge_hookMethodNative and is defined in [libxposed_art.cpp](https://github.com/rovo89/Xposed/blob/4b9a7a612c180dc47019724a8e66e79f4f5e7e83/libxposed_art.cpp#L78)

hookMethodNative executes the following lines of code,

```java
// Get the ArtMethod of the method to be hooked.
ArtMethod* artMethod = ArtMethod::FromReflectedMethod(soa, javaReflectedMethod);

// Hook the method
artMethod->EnableXposedHook(soa, javaAdditionalInfo);
```

### The final piece of the puzzle - ART Magic
Thus we see that hookMethodNative gets the ARTMethod from the javaReflectedMethod passed in and
executes EnableXposedHook on the ARTMethod with additionalInfo (which contains all the callbacks) as a parameter.
Note that at runtime, all method calls (be it JNI or Java) are represented with ArtMethod which is a structure containing
the method header information alongwith other information such as the method entry point address.

Let us start gazing [here](https://github.com/rovo89/android_art/blob/1076fab144164b4862641720da5f91e1e519130e/runtime/art_method.cc#L552) to see what EnableXposedHook does:

It uses the runtime class linker to allocate a new method structure for our class.
Then it copies the ArtMethod corresponding to the method being invoked into this newly allocated runtime method.
We call this the "backed up method", in our case a clone of updateClock().
Next we create a Java reflected method from this clone. We call it reflected_method.

We initialize a new struct XposedHookInfo which looks like:
```c
struct XposedHookInfo {
  jobject reflected_method; // refleced method goes here
  jobject additional_info; // our callbacks are here
  ArtMethod* original_method; // backup method goes here
};
```

Next JIT is invoked to do some important bookkeeping.

Finally, the following two lines accomplish a lot.

```c
// sets the ArtMethod property of entryPointFromJni to point to our XposedHookInfo object
SetEntryPointFromJniPtrSize(reinterpret_cast<uint8_t*>(hook_info), sizeof(void*));
// Explained below
SetEntryPointFromQuickCompiledCode(GetQuickProxyInvokeHandler());
```

GetQuickProxyInvokeHandler returns a pointer to art_quick_proxy_invoke_handler,
```c
// Return the address of quick stub code for handling transitions into the proxy invoke handler.
extern "C" void art_quick_proxy_invoke_handler();
static inline const void* GetQuickProxyInvokeHandler() {
  return reinterpret_cast<const void*>(art_quick_proxy_invoke_handler);
}
```

which is an assembly routine defined [here](https://github.com/rovo89/android_art/blob/1076fab144164b4862641720da5f91e1e519130e/runtime/arch/arm64/quick_entrypoints_arm64.S#L1809),

```assembly
ENTRY art_quick_proxy_invoke_handler
    SETUP_REFS_AND_ARGS_CALLEE_SAVE_FRAME_WITH_METHOD_IN_X0
    mov     x2, xSELF                   // pass Thread::Current
    mov     x3, sp                      // pass SP
    bl      artQuickProxyInvokeHandler  // (Method* proxy method, receiver, Thread*, SP)
    ldr     x2, [xSELF, THREAD_EXCEPTION_OFFSET]
    cbnz    x2, .Lexception_in_proxy    // success if no exception is pending
    RESTORE_REFS_AND_ARGS_CALLEE_SAVE_FRAME // Restore frame
    fmov    d0, x0                      // Store result in d0 in case it was float or double
    ret                                 // return on success
.Lexception_in_proxy:
    RESTORE_REFS_AND_ARGS_CALLEE_SAVE_FRAME
    DELIVER_PENDING_EXCEPTION
END art_quick_proxy_invoke_handler
```

It eventually invokes artQuickProxyInvokeHandler as shown above after setting up the registers.
artQuickProxyHandler eventually executes the following [lines](https://github.com/rovo89/android_art/blob/1076fab144164b4862641720da5f91e1e519130e/runtime/entrypoints/quick/quick_trampoline_entrypoints.cc#L876):

```
if (is_xposed) {
    jmethodID proxy_methodid = soa.EncodeMethod(proxy_method);
    self->EndAssertNoThreadSuspension(old_cause);
    JValue result = InvokeXposedHandleHookedMethod(soa, shorty, rcvr_jobj, proxy_methodid, args);
    local_ref_visitor.FixupReferences();
    return result.GetJ();
}
```

InvokeXposedHandleHookedMethod gets the XposedHookInfo from the ArtMethod instance of updateClock(), and [calls](https://github.com/rovo89/android_art/blob/1076fab144164b4862641720da5f91e1e519130e/runtime/entrypoints/entrypoint_utils.cc#L279)
```
soa.Env()->CallStaticObjectMethodA(ArtMethod::xposed_callback_class,
                                         ArtMethod::xposed_callback_method,
                                         invocation_args);
```


This takes us to the "handleHookedMethod", mentioned earlier.
We are back in Java land now, in [XposedBridge.java](https://github.com/rovo89/XposedBridge/blob/art/app/src/main/java/de/robv/android/xposed/XposedBridge.java#L307) to be precise. This is simple Java code which calls the "beforeHooked" callbacks 
followed by a JNI call to invokeOriginalMethodNative with the original methodId and ultimately the "afterHooked" callbacks.

invokeOriginalMethodNative defined [here](https://github.com/rovo89/Xposed/blob/4b9a7a612c180dc47019724a8e66e79f4f5e7e83/libxposed_art.cpp#L98) does nothing fancy, simply gets the ArtMethod instance of updateClock(), calls it using InvokeMethod.

Finally our "afterHooked" callbacks are called in [here](https://github.com/rovo89/XposedBridge/blob/art/app/src/main/java/de/robv/android/xposed/XposedBridge.java#L374).


### References/Notes

ART/Dalvik itself which has been fundamentally modified by Xposed via modifying dex2oat primarily. ART does a few optimizations such as method inlining for short methods and direct calls to framework methods.
Xposed disabled these optimizations. This way, all calls will require to lookup the methods entry point in the
ArtMethod object corresponding to the method being called. Note that at runtime, all method calls (be it JNI or Java) are represented with ArtMethod.

```c
class ArtMethod{
 Class  declaringClass;
 ArtMethod []  dexCacheResolvedMethods;
//  These  caches  are  used  when
 Class[]  dexCacheResolvedClasses;
//  resolving  methods ,  classes  or
 String []  dexCacheStrings;
//  strings  from  the  dex  file  index
/**
* Method dispatch from the interpreter invokes this pointer which may cause a bridge into
* compiled code.
*/
 private long entryPointFromInterpreter;
/**
* Pointer to JNI function registered to this method, or a function to resolve the JNI function.
*/
 private long entryPointFromJni;
/**
* Method dispatch from portable compiled code invokes this pointer which may cause bridging
* into quick compiled code or the interpreter.
*/
 private long entryPointFromPortableCompiledCode;
/**
* Method dispatch from quick compiled code invokes this pointer which may cause bridging
* into portable compiled code or the interpreter.
*/
 private long entryPointFromQuickCompiledCode;
 long garbageCollectorMap;
 int accessFlags;
 int dexCodeItemOffset;
 int dexMethodIndex;
 int methodIndex;
}
```
