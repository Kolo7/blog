# java并发编程

----

## 3.  java内存模型

​	java对内存的管理使用了自己的内存模型，称之为JMM。

### 3.1 内存模型的基础

#### 3.1.1 并发编程的两个关键问题

​	线程间如何通信以及线程间如何同步。

​	通信的机制有两种：共享内存和消息传递。

#### 3.1.2 java内存模型的抽象结构

​	java中堆内存是共享的，在内存模型中，堆内存就充当着主内存的地位。

​	不同线程间共享一个主内存，共享变量存在主内存中，每个线程又存在着自己的私有内存，保存着主内存中共享变量的副本。

​	不同线程间通过对共享变量的读写，来完成不同线程间的通信。

​	线程先将消息写入私有内存，然后在合适的时机将私有内存中的共享变量刷新到主内存中覆盖原有的值，其他的变量在合适的时机读取主内存中的值到自己的私有变量中覆盖对应的共享变量，从而完成了线程间的通信。

#### 3.1.3 从源代码到指令序列的重排序

​	执行程序，为了提高性能，编译器和处理器都会对指令进行重排序。重排序分三种：

- 编译器优化重排序；
- 指令级并行重排序；
- 内存系统重排序。

> 第一个是编译器级别重排序，后两个属于处理器级别重排序。

​	这些重排序可能会导致程序产生内存可见性问题，对于编译器，JMM的编译器重排序规则会禁止特定类型的重排序。对处理器，JMM会在生成指令序列期间插入内存屏障指令禁止特定类型的处理器重排序。

#### 3.1.4 并发编程模型的分类

> ps：这一小节的名字和内容不够符合。可能`处理器写缓冲和内存可见性保证`会更好。

​	现代处理器，都使用了写缓冲区临时保存向内存中写入的数据。这样好处多多，但是会影响到内存读/写执行顺序。

> 例如：本来应该先写后读，但是由于是写入到写缓冲区中，对其他线程而言，看到的就变成了先读后写了。这就是内存系统的重排序。

​	上述的重排序类型是写-读操作，也就Store-Load，不同的处理器支持的内存重排序类型不一样。

> 记住一点就够了，几乎所有的处理器都允许Store-Load重排序，这是因为写缓冲区的广泛使用导致的。

​	对这种重排序带来的问题的解决方法就是使用内存屏障。对域每一种内存重排序，都对应了一种内存屏障。也就是禁止这种重排序的发生。

> StoreStore Barriers：确保前一条写指令对其他处理器的可见先于后一条指令以及后续指令的存储。这是一个全能的屏障，同时具有其他三个屏障的效果。它就是将前一条指令的操作刷新到内存中去。

#### 3.1.5 happens-before简介

​	JMM中，如果一个操作的执行结果需要对另外一个操作可见，那么两个操作必须存在happens-before关系。

happens-before规则如下：

- 程序顺序规则：一个线程中的每个操作，happens-before于该线程中任意后续操作。
- 监控器锁规则：对一个锁的解锁，happens-before于随后对这个锁的加锁。
- volatile变量规则：对一个volatile变量的写，happens-before于任意后续对这个变量的读。
- 传递性：略。

> happens-before不意味着前者操作必须在后者之前执行，要求的是，前一个操作对后一个操作可见。这是很微妙的关系。

​	对JMM而言，它通过禁止某种编译器级和处理器级重排序来做到happens-before规则。而java程序员就不需要知道复杂的重排序规则和这些规则具体的实现方法。

### 3.2 重排序

#### 3.2.1 数据依赖性

​	如果两个操作访问同一个变量，并且这两个操作有一个是写操作，那么两个操作具有数据依赖性。

​	数据依赖分为三种：

- 写后读
- 写后写
- 读后写



​	上面三种数据依赖，只要重排序这两个操作，那么执行的结果就会发生改变。因此，编译器和处理器不会改变存在数据依赖的两个操作的执行顺序。当然这只针对单线程内，单处理器内而言。

#### 3.2.2 as-if-serial语义

​	as-if-serial语义的意思是：不管怎么重排序，单线程的执行结果不会发生改变。

​	为了遵循单线程内的as-if-serial语义，编译器和处理器都禁止对存在数据依赖的操作重排序。

​	as-if-serial语义将单线程程序保护起来，使得程序员产生一种幻觉：单线程程序是按照程序源代码的顺序来执行的。

#### 3.2.3 程序循序规则

总之就一条，在不违反happens-before规则的前提下，程序内的执行顺序是可以任意重排序的，以此来提高执行效率。

#### 3.2.4 重排序对多线程的影响

```java
public class ReorderExample{
    int a = 0;
    boolean flag = false;
    public void writer(){
        a = 1;				// 1
        flag = true;		// 2
    }
    public void reader(){
        if(flag)			// 3
            int i = a*a;	// 4
    }
}
```

​	上面代码的如果采用两个线程先执行`writer()`，后执行`reader()`方法，在执行4的时候能否看到a=1呢。结果是不一定能，因为1和2操作还有3和4不存在数据依赖，因此执行顺序不一定。

​	如果是对1和2重排序，那么i就有可能是=0。

​	还有一种可能3和4重排序，3和4之间不存在数据依赖，但是存在控制依赖，一般编译器和处理器会采用猜测执行来克服控制相关对并行性的影响。所以可能先执行4，把4的结果保存到重排序缓冲中，当3的结果为真的时候，就把该结果写入i。

​	单线程中就算采用猜测执行重排序，也不会影响执行结果，没有违背as-if-serial规则，但是在多线程中，可能就影响了。

### 3.3 顺序一致性

顺序一致性是一个理论参考模型。

#### 3.3.1 数据竞争和顺序一致性

​	数据竞争：在一个线程中写入一个变量，在另一个线程读取这个变量，写和读之间未同步。如果一个程序能正确同步，那么这个程序是不存在数据竞争的。

​	JMM保证，对域正确同步的程序，程序的执行将具有顺序一致性，即程序的执行结果与该程序在顺序一致性内存模型中执行结果是一致的。

#### 3.3.2 顺序一致性内存模型

特性：

- 一个线程内所有的操作必须按照程序的顺序来执行。
- 不管程序是否同步，所有线程都只能看到一个单一的操作执行顺序。在顺序一致性内存模型中，每个操作都必须原子执行且立即对所有线程可见。

> 对后一条我的理解是，如果线程存在类似写缓冲区，这样的私有内存，那么私有内存未及时同主内存同步的话，就会产生线程看到的执行顺序不一致的情况。而线程同步就会完全的避免这样的发生。

#### 3.3.3 同步程序的顺序一致性效果

​	对于JMM规范，并没有遵守顺序一致性内存模型的第一条，也就是临界段内的操作是可以重排序的，但是不可以逸出到临界段之外。这样子既提高了程序执行效率，也不会改变程序的执行结果。

​	基本方针：在不改变程序执行结果的前提下，尽可能的为编译器和处理器的优化提供方便。

#### 3.3.4 未同步程序的执行特性

​	对于未同步的多线程程序，JMM只提供最小安全性：线程执行时读取到的值，要么是之前某个线程写入的值，要么是默认值，JMM保证读取得到的值不会是无中生有。

​	为了保证最小安全性，JVM在对上分配对象时，首先对内存空间清零，然后才会在上面分配对象。这两个操作会自动同步。

​	未同步程序在JMM的执行时，和在顺序一致性模型上执行有一些差异：

​	1）顺序一致性模型保证单线程内的操作会按照程序的顺序执行，而JMM不会保证，这是为了重排序优化执行效率。

​	2）顺序一致性模型保证所有线程只能看到一致的操作执行顺序，而JMM不保证，这是因为使用了线程私有内存，内存重排序		   优化导致的。

​	3）JMM不保证对64位的long型和double型数据的写操作具有原子性。如果要保证原子读写，那么要使用特别的类。

### 3.4 volatile的内存语义

​	当声明共享变量为volatile后，对这个变量的读写将会变得不一样。

#### 3.4.1 volatile的特性

​	理解volitile特性一个方法就是把它看作是，使用同一个锁对这些单个的读/写操作进行了同步操作。实例：

```java
class VolatileFeturesExample{
    volatile long vl = 0L;
    
    public void set(long l){
        vl = l;
    }
    public void getAndIncrement(){
        vl++;
    }
    public long get(){
        return vl;
    }
}

class VolitileFeaturesExample{
    long vl = 0L;
    public synchronized void (long l){
        vl = l;
    }
    public void getAndIncrement(){
        long temp = get();
        temp += 1;
        set(temp);
    }
    public synchronized long get(){
        return vl;
    }
}
```

​	上面两个类的效果是一样的。

​	volatile的特性：

- 可见性。保证此变量对所有线程的可见性，也就是所有线程对该变量看到的操作顺序是一致的。
- 禁止指令重排序。
- 保证long型和double型的原子性。

> 可以这么理解，JMM为了保证可见性，对于标记有volatile变量，写的时候直接写入主内存中，而不是私有内存；读的时候，直接从主内存中去读，而私有内存设置为无效。为了保证指令重排序，在对volatile变量读写的指令前后插入内存屏障，禁止前后的特定的指令重排序。

#### 3.4.2 volatile读-写建立的happens-before关系

​	volatile的写-读，与锁的释放-获取有相同的内存效果。也就说从内存效果而言，volatile可以取代锁。因此产生的happens-before关系是相同的。

#### 3.4.3 volatile的读-写内存语义

​	对于标记有volatile变量，写的时候直接写入主内存中，而不是私有内存；读的时候，直接从主内存中去读，而私有内存设置为无效。

​	从内存语义来看：

- 线程A写入一个volatile变量，实质上是线程A向共享内存中发出一个消息。
- 线程B读一个volatile变量，实质上是线程B从共享内存中读取之前某个线程发出的消息。

#### 3.4.4 volatile内存语义的实现

| 是否能重排序 |          |            | 第二个操作 |
| ------------ | -------- | ---------- | ---------- |
| 第一个操作   | 普通读写 | volatile读 | volatile写 |
| 普通读写     |          |            | NO         |
| volatile读   | NO       | NO         | NO         |
| volatile写   |          | NO         | NO         |

- volatile写操作之前的操作不会被重排序到volatile写操作之后。
- volatile读操作之后的操作不会被重排序到volatile读操作之前。
- volatile操作之间的执行顺序是不会重排序的。

取得这些效果的方法就是插入内存屏障，禁止特定类型的处理器重排序。具体是什么暂时不需要明白。

#### 3.4.5 JSP-133为什么增强volatile的内存语义

​	在旧的内存模型中，volatile写-读没有锁的释放-获取所具有的内存语义。为了提供一种比锁更轻量级的线程之间通讯的机制，增强了volatile的内存语义，禁止volatile变量和普通变量的重排序。

>  [Java 理论与实践：正确使用 Volatile 变量](https://www.ibm.com/developerworks/cn/java/j-jtp06197.html#icomments) 具体使用volatile的场景，可以查看这篇文章。

对于这边文章的场景案例进行一些解读：

模式 #1：状态标志

```java
volatile boolean shutdownRequested;
 
...
 
public void shutdown() { shutdownRequested = true; }
 
public void doWork() { 
    while (!shutdownRequested) { 
        // do stuff
    }
}
```

> ​	这个案例中，使用volatile变量，提供可见性，一个线程执行`shutdown()`另外的其他线程都可以立马得到通知。而普通的变量的话，会产生一些不小的延迟，这对程序的逻辑性可能会产生影响。而使用锁的话，不够简洁，而且线程串行化，效率太低。

模式 #2：一次性安全发布

```java
public class BackgroundFloobleLoader {
    public volatile Flooble theFlooble;
 
    public void initInBackground() {
        // do lots of stuff
        theFlooble = new Flooble();  // this is the only write to theFlooble
    }
}
 
public class SomeOtherClass {
    public void doWork() {
        while (true) { 
            // do some stuff...
            // use the Flooble, but only if it is ready
            if (floobleLoader.theFlooble != null) 
                doSomething(floobleLoader.theFlooble);
        }
    }
}
```

>​	对于这个案例，它除了和上一个案例一样，利用了可见性，最主要的是利用了禁止指令重排。如果没有volatile，在initInBackfround()中的指令是会重排序的，因此有可能还没完成初始化工作，就先`new Floooble()`执行了，对其他线程而言，获取到了更新好的引用值，但是却发现对象的初始化还未完成。这和我们的初衷是违背的。

模式 #4：“volatile bean” 模式

```java
public class Person {
    private volatile String firstName;
    private volatile String lastName;
    private volatile int age;
 
    public String getFirstName() { return firstName; }
    public String getLastName() { return lastName; }
    public int getAge() { return age; }
 
    public void setFirstName(String firstName) { 
        this.firstName = firstName;
    }
 
    public void setLastName(String lastName) { 
        this.lastName = lastName;
    }
 
    public void setAge(int age) { 
        this.age = age;
    }
}
```

> ​	这个模式除了对所有的成员变量加了volatile之外，还要求是有效不可变的值，数组不可以，否则的话，volatile不能保证对成员变量内的修改是所有线程可见的，所以干脆就不能用可变的对象和数组。



### 3.5 锁的内存语义

### 3.6 final的内存语义

### 3.7 happens-before

### 3.8 双重检查锁定和延迟初始化

### 3.9 Java内存模型综述

