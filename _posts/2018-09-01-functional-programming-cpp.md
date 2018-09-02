---
layout: post
title:  "Functional Programming with C++ 2017"
date:   2018-09-01 12:00:00
categories: c++ functional
---
Designing high performance applications is difficult without the knowledge of parallel programing. We will achieve the full usage of all cpu cores using functional programming and C++ 2017 parallel algorithms.

##### TL;DR
Parallel Euclidean distance:

$$\sqrt {\sum _{i=1}^{n}(x_{i}-y_{i})^{2}}$$

```cpp
   vector<double> v1 = { 1.0, 0.0, 0.0 };
   vector<double> v2 = { 1.0, 1.0, 0.0 };
   //euclidean distance
   auto euclidean = sqrt(transform_reduce(execution::par,v1.begin(),v1.end(),v2.begin(),0.0,
                      [] (auto x, auto y) -> auto {return x+y;},
                      [] (auto x, auto y) -> auto {return (x-y)*(x-y);}
                     ));
   cout << euclidean << endl;
```
result:
```cpp
1
```
##### DISCLAIMER
C++ 17 Standards are too new to be production ready. There are no big compiler vendors that provide STL parallel algorithms at this moment. All this examples are created using Intel® Parallel STL.

[Status of gcc C++ 2017 Support](https://gcc.gnu.org/onlinedocs/libstdc++/manual/status.html#status.iso.2017)

[Status of MSVC++ 2017 Support](https://blogs.msdn.microsoft.com/vcblog/2017/12/19/c17-progress-in-vs-2017-15-5-and-15-6/)

I will do a small tutorial for set up the environment but is only for linux + g++ + gentoo.
If you don't have this environment, you have to do by your own.

##### Intel® Parallel STL Installation
[See documentation](https://software.intel.com/en-us/get-started-with-pstl)
1. Install gcc with support for OpenMP and C++11
```bash
sudo USE="openmp" emerge sys-devel/gcc --ask
```
2. Install Intel® TBB 2018
```bash
sudo emerge =dev-cpp/tbb-2018.20180312 --ask
```
3. Clone the Intel® Parallel STL
```
git clone https://github.com/intel/parallelstl.git
```
4. Remember the path of include folder for later

##### Functional Programming
Functional programming is a programming paradigm that allows the programmer to relax the definition of the control flow relying in our compiler .

When using imperative programming we are telling to the compiler exactly what It have to do, ending in a not too much performant code.

###### Example for loop
* Imperative
```cpp
for(auto i = 0; i<N; i++){
   something(array[i]);
}
```
You as a programmer are telling to the compiler to do the following:
1. Initialize iterator
2. do something with an array
3. Increment iterator
4. Test condition and jump backwards

As you can see this definition is too strict and the compiler can't optimize your code because It can't understand what you want to do.
* Functional Programming
```cpp
for_each(array.begin(), array.end(),
[] (auto element) -> auto {return something(element););
```
As you can see the meaning of this loop has changed a little bit to the following:
5. Do some stuff with each element. I don't care how you are doing It. But I still want to preserve the execution order.

##### C++ 2017 Parallel Algorithms
Once we understand the power of functional programming and the compiler have more room to improve our code, C++17 defines a way to run code very efficiently.
###### Execution Policies
[See documentation](https://en.cppreference.com/w/cpp/algorithm/execution_policy_tag_t)
A execution policy is a way to hint the compiler If you want to continue executing your code sequentially or if you want the compiler parallelize for you.
* __std::execution::seq__: I want to preserve the original sequential behaviour.
* __std::execution::par__: I want the compiler to parallelize my code
* __std::execution::par_unseq__: The compiler tries to parallelize and vectorize the loop.

##### Example of Parallel STL Code
Understanding the STL Algorithms is not in the scope of this tutorial. It is granted you are a c++ developer and know some of the following algorithms:
* [std::for_each](https://en.cppreference.com/w/cpp/algorithm/for_each)
* [std::reduce](https://en.cppreference.com/w/cpp/algorithm/reduce)
* [std::transform](https://en.cppreference.com/w/cpp/algorithm/transform)
* [std::transform_reduce](https://en.cppreference.com/w/cpp/algorithm/transform_reduce)

```cpp
#include <iostream>
#include <vector>
#include <cmath>
#include "pstl/algorithm"
#include "pstl/execution"
#include "pstl/numeric"
using namespace std;

const int MAX_SIZE = 100000000;
int main(){
    //initialize vector with zeroes
   vector<int> v = vector(MAX_SIZE,0);
   //initialize vector with ones
   transform(execution::par,v.begin(),v.end(),v.begin(),[] (int x) -> auto { return 1;});

   //get some random numbers
   transform(execution::par,v.begin(),v.end(),v.begin(),[] (int x) -> auto { return rand()-(RAND_MAX/2);});

   //calculate ABS
   transform(execution::par,v.begin(),v.end(),v.begin(),[] (int x) -> auto { return abs(x);});

   for_each(execution::seq,v.begin(), v.end(), [] (int x) -> auto { cout << x << endl; });

```
This code computes the absolute value of a integer vector
1. First we initialize the vector with zeroes and then with ones
```cpp
    //initialize vector with zeroes
   vector<int> v = vector(MAX_SIZE,0);
   //initialize vector with ones
   transform(execution::par,v.begin(),v.end(),v.begin(),[] (int x) -> auto { return 1;});
```
2. Second we generate some random numbers
```cpp
   //get some random numbers
   transform(execution::par,v.begin(),v.end(),v.begin(),[] (int x) -> auto { return rand()-(RAND_MAX/2);});
```
3. Third we compute the abs()
```cpp
   //calculate ABS
   transform(execution::par,v.begin(),v.end(),v.begin(),[] (int x) -> auto { return abs(x);});
```
4. Print the vector in std out sequentially to avoid data races
```cpp
   for_each(execution::seq,v.begin(), v.end(), [] (int x) -> auto { cout << x << endl; });
```

##### Parallel Euclidean Distance

$$\sqrt {\sum _{i=1}^{n}(x_{i}-y_{i})^{2}}$$

```cpp
   vector<double> v1 = { 1.0, 0.0, 0.0 };
   vector<double> v2 = { 1.0, 1.0, 0.0 };
   //euclidean distance
   auto euclidean = sqrt(transform_reduce(execution::par,v1.begin(),v1.end(),v2.begin(),
                      //initial reduce value
                      0.0,
                      //reduce function: sum
                      [] (auto x, auto y) -> auto {return x+y;},
                      //transform function: substract^2
                      [] (auto x, auto y) -> auto {return (x-y)*(x-y);}
                     ));
   cout << euclidean << endl;
```
1. First we initialize the input vectors
```cpp
 vector<double> v1 = { 1.0, 0.0, 0.0 };
 vector<double> v2 = { 1.0, 1.0, 0.0 };
```
2. For every pair from x and y, compute transform (x-y)^2
```cpp
[] (auto x, auto y) -> auto {return (x-y)*(x-y)
```
3. The result of the transform will be used in the parallel reduce adding all elements.
```cpp
[] (auto x, auto y) -> auto {return x+y;}
```

##### Compiling our code
After having our environment installed, we need to compile our code.
```bash
CPATH=/path_to_parallelstl/include g++ -std=c++17 main.cpp -ltbb
```
* We are forcing to use the new stl with the CPATH env var.
* We are forcing C++17 standard
* We are linking with [Intel® TBB Threading Building Blocks](https://www.threadingbuildingblocks.org/)

##### Conclusions
Learning parallel programming is too difficult because our mindset is too much attached to imperative programming.

When we start to code in functional programming, mutual exclusion and data races are less common because our data structure is independant between iterations.

We still have to be careful about thread safe algorithm. But If you use lambdas and the input and output are different in each iteration of the _loop_, You will end up with high performant code.

##### Next Steps
Nowadays, a computer is a heterogeneous system with too many processors.

Some of them are called CPU, others are called GPU and others are called FPGA.

Khronos(R) Group is investing in [SYCL](https://github.com/KhronosGroup/SyclParallelSTL) library. A high performance library to bring C++ 2017 code in all this devices.

* [Single source SYCL C++ on Xilinx FPGA](https://www.youtube.com/watch?v=4r6FXxknJEA)
* [ComputeCPP](https://www.codeplay.com/products/computesuite/computecpp): A library for execute C++ code in GPUs

I Hope you enjoy this post.
