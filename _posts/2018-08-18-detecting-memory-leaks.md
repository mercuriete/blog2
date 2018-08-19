---
layout: post
title:  "Detecting memory leaks in c++ code"
date:   2018-08-18 12:00:00
categories: c++
---
Memory leaks are a very common problem in c++ development that can cause severe
problems due to difficult to found the problem.

##### Windows version

For finding memory leaks in Microsoft Visual Studio builds we are using CRT library following the official documentation.
[Finding Memory Leaks Using the CRT Library](https://docs.microsoft.com/visualstudio/debugger/finding-memory-leaks-using-the-crt-library).

I created a helper to make more usable that library. I will explain it line by line
[Memory leak detection helper](https://github.com/mercuriete/cpp-memory-leak-detection/blob/master/lib/include/memory_leak.h)

##### Preprocesor header
```
#ifndef MEMORY_LEAK_HPP
#define MEMORY_LEAK_HPP
#if defined(_WIN32) || defined(_WIN64)
#ifdef _DEBUG
```
We only want to generate code in windows architectures and only when debugging.

##### macro for new expansion
```
#define DBG_NEW new ( _NORMAL_BLOCK , __FILE__ , __LINE__ )
#define new DBG_NEW
```
This automatically expands a new sentence into a new ( _NORMAL_BLOCK , FILE , LINE )

The purpouse of this macro is to have more accurate line count in the memory leak reports

##### library initialization
```
int initialize_memory_leak_detector(){
   std::cout << "initializing memory leak detector" << std::endl;
   _CrtSetDbgFlag ( _CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF );
   return 0;
}
int memory_leak_initizalization_result = initialize_memory_leak_detector();
```
This global variable is useless but this triggers a initialization before the main was called. Probably this sentence is called before your code is started.

This function sets debug flags according with the microsoft documentation for dump a memory leak report on exit of your application

##### at exit handler
```
void atexit_handler(){
   int result = 0;
   std::cout << "ending memory leak detector and dumping report" << std::endl;
   if ((result = _CrtDumpMemoryLeaks()) != 0) {
      std::cout << "memory leak detected. please debug with Visual Studio" << std::endl;
   }
   else{
      std::cout << "no memory leaks detected" << std::endl;
   }
   //Hahahahaha exit on an exit handler!
   //feel free to blame me if you get something really bad.
exit(result);
}

int memory_leak_dump_report_at_exit = std::atexit(atexit_handler);
```
This function is registered at start of your application and is called just before you application is exiting. This dumps a memory leak report on debug logger that is not available to read in continuous integration tools. This is why we exit with an exit code to break the continous integration pipeline once we detect a memory leak.

As you can see, I am calling exit inside an at exit handler. This is totally forbidden due to a possible infinite loop but it works as I intended.

##### Linux & Mac version
On Unix systems ASAN library from google will be used. This library is integrated in g++ and clang compilers and can be used as easy as setting a flag during comilation.

[example on github](https://github.com/mercuriete/cpp-memory-leak-detection/blob/develop/CMakeLists.txt#L11)

The only thing we need to do is pass to the compiler the flags:

```
-g -O0 -fsanitize=leak"
```
-g: is for debugging symbols

-o0 is for don't optimization for accurate line number count

-fsanitize=leak is for activate ASAN with low overhead only detecting leaks.

Then when you start you application you will need to add an enviromental variable
[example on travis](https://github.com/mercuriete/cpp-memory-leak-detection/blob/develop/.travis.yml#L107)

```
ASAN_OPTIONS=detect_leaks=1 ./app
```

with that done you will have something like this:
[travis build log](https://travis-ci.org/mercuriete/cpp-memory-leak-detection/jobs/417463458#L686)

```
Direct leak of 8 byte(s) in 1 object(s) allocated from:

 #0 0x7fb8069879f8 in operator new(unsigned long) (liblsan.so.0+0xf9f8)

 #1 0x40bd8c in main /app/src/main.cpp:13

 #2 0x7fb8060a2f44 in __libc_start_main (libc.so.6+0x21f44)
```

then you can go to the [offending line](https://github.com/mercuriete/cpp-memory-leak-detection/blob/develop/app/src/main.cpp#L13) and check what is happening

```
string* leaking_pointer = new string("leaking object");

//You forgot to delete pointer

leaking_pointer = new string("Hello, World!");

cout << *leaking_pointer << endl;

delete leaking_pointer;
```

Is really obvious whats going on. You forgot to delete a pointer before reuse for another instance.

##### Conclusions
Given that I have a bias about linux vs windows, Is obvious to understand that on the windows counterpart you have to modify your code a little bit in order to enable memory sanitizer tools.
With ASAN you only need to compile you code with debug symbols and ASAN will take care of analyze the heap for you.

Summarizing, there are some tools that can improve our code quality with a little bit of effort. This days are not acceptable to have such a problem comparing with days when instrumenting your application were more difficult.
