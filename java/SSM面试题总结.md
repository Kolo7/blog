# SSM面试题总结

### Spring源码解析

#### 一、创建BeanFactory

创建BeanFactory入口：

```math

|--AbstractApplicationContext.refresh()
	|--AbstractApplicationContext.obtainFreshBeanFactory()											#创建一个新的IOC容器：DefaultListableBeanFactory
		|--AbstractRefreshableApplicationContext.refreshBeanFactory()								#销毁以前的容器，创建新的，加载BeanDefinition对象到容器中
			|--AbstractRefreshableApplicationContext.loadBeanDefinitions()

```

#### 二、创建BeanDefinition

创建BeanDefinition入口：

```math
|--AbstractRefreshableApplicationContext.loadBeanDefinitions()										#对BeanFactory进行创建和对BeanDefinition定义、注册
	|--AbstractXmlApplicationContext.loadBeanDefinitions()											#多层重载，对Xml资源进行加载
			|--AbstractBeanDefinitionReader.loadBeanDefinitions()									#经过三层重载，对BeanDefinition读取，具体工作交给子类
				|--XmlBeanDefinitionReader.loadBeanDefinitions()									#通过DOM4J，对Xml资源读取、解析，对BeanDefinition注册
					doLoadBeanDefinitions()
                    	registerBeanDefinitions()													#多层重载				
                    		doRegisterBeanDefinitions()
								parseBeanDefinitions()		
									parseDefaultElement()
										processBeanDefinition()
											|--BeanDefinitionParseDelegate.parseBeanDefinitionElement()		#多层重载
												createBeanDefinition()										#根据classname和classloader创建Definition
												parseBeanDefinitionAttributes()								#根据文档，设置属性
												parsePropertyElements()										#多层重载，property标签处理
											|--BeanDefinitionReaderUtils.registerBeanDefinition()
												|--BeanDefinitionRegistry.registerBeanDefinition()		#这里的BeanDefinitionRegistry其实是子类DefaultListableBeanFactory
												
				
```

### Spring设计模式分析

#### 1. 模板方法

在父类中定义算法的主要流程，而把一些个性化的步骤延迟到子类中去实现，父类始终控制着整个流程的主动权，子类只是辅助父类实现某些可定制的步骤。

具体在哪有体现，我没找到 。

#### 2. 策略模式



#### 3. 简单工厂

体现在每当需要从BeanFactory中得到一个Bean的时候，根据唯一的标识，获取对应的Bean。

#### 4. 工厂方法 

工厂方法在与简单工厂不同点在于，工厂有了自己的种类，不同的工厂生成不同的Bean，这样易于扩展生产新的Bean，不需要修改原有工厂的代码，而是扩展一个新的工厂。

有两种体现：

1. 静态工厂方法

无需实例化工厂，需要在config中指定静态工厂方法。还可以为方法传参。具体Bean对象怎么实例化，由工厂类决定。

```xml
<bean id="bmwCar" class="com.home.factoryMethod.CarStaticFactory" factory-method="getCar">
        <constructor-arg value="3"></constructor-arg>           
    </bean>
```
2.	实例化工厂方法

先实例化工厂对象，可以对工厂完成装配，再指定工厂方法。工厂的指定更加灵活，而不是绑定。

```xml
<bean id="carFactory" calss="com.home.factoryMethod.CarFactory">
    <property name="" value=""></property>
    <property name="" ref=""></property>
</bean>

<bean id="cat" factory-bean="carFactory" factory-method="getCar">
	<constructor-arg value="4"></constructor-arg>
</bean>
```

还有一种获取bean的方法，FactoryBean；
FactoryBean：以Bean结尾，表示它是一个Bean，不同于普通Bean的是：它是实现了FactoryBean\<T\>接口的Bean，根据该Bean的Id从BeanFactory中获取的实际上是FactoryBean的getObject()返回的对象，而不是FactoryBean本身， 如果要获取FactoryBean对象，可以在id前面加一个&符号来获取。

#### 5. 单例模式

spring中的单例模式完成了后半句话，即提供了全局的访问点BeanFactory。但没有从构造器级别去控制单例，这是因为spring管理的是任意的java对象。

也就是说，spring没有通过私有化构造器来阻止new对象，但是从spring的BeanFactory中获取的一定是同一个对象。

#### 5. 代理

spring中AOP部分，一般采用JDK动态代理，如果被代理对象未实现任何接口，那么就是用CGlib的字节码生成技术。

#### 7. 适配器模式

#### 8. 装饰者模式

动态地给一个对象添加一些额外的职责。

spring的applicationContext中配置所有的dataSource。这些dataSource可能是各种不同类型的，比如不同的数据库：Oracle、SQL Server、MySQL等，也可能是不同的数据源：比如apache 提供的org.apache.commons.dbcp.BasicDataSource、spring提供的org.springframework.jndi.JndiObjectFactoryBean等。然后sessionFactory根据客户的每次请求，将dataSource属性设置成不同的数据源，以到达切换数据源的目的。

#### 9. 观察者模式

定义对象间的一种一对多的依赖关系，当一个对象的状态发生改变时，所有依赖于它的对象都得到通知并被自动更新。

ApplicationListener

### spring MVC的启动流程

#### 1. Web应用部署初始化过程

- 部署描述文件中(eg.tomcat的web.xml)由`<listener>`元素标记的事件监听器会被创建和初始化

- 对于所有事件监听器，如果实现了`ServletContextListener`接口，将会执行其实现的`contextInitialized()`方法

- 部署描述文件中由`<filter>`元素标记的过滤器会被创建和初始化，并调用其`init()`方法

- 部署描述文件中由`<servlet>`元素标记的servlet会根据`<load-on-startup>`的权值按顺序创建和初始化，并调用其`init()`方法

#### 2. Spring MVC启动过程

- 首先定义了`<context-param>`标签，用于配置一个全局变量，`<context-param>`标签的内容读取后会被放进`application`中，做为Web应用的全局变量使用。接下来创建`listener`时会使用到这个全局变量。
- 接着定义了一个`ContextLoaderListener类`的`listener`,该类实现了ServletContextListener，实现两个监听方法，分别监听web应用的初始化和销毁事件，在web应用初始化的时候初始化IOC容器。这个IOC容器是根容器，包含的是最重要的全局配置，例如DataSource，事务等。
- 接下来会进行`filter`的初始化操作。这不是必须的。
- `Web应用`启动的最后一个步骤就是创建和初始化相关`Servlet`，在开发中常用的`Servlet`就是`DispatcherServlet类`前端控制器，前端控制器作为中央控制器是整个`Web应用`的核心，用于获取分发用户请求并返回响应。通过继承自父类的方法，同样是要创建WebApplicationContext也就是IOC容器，这个容器继承自根容器，形成父子容器效果。子容器中的Bean一般是局部的，类似`Controller`、`Interceptor`、`Converter`、`ExceptionResolver`。子容器构造完成后，初始化一系列SpringMVC重要组件，

##### 摘录

1、解析`<context-param>`里的键值对。

2、创建一个`application`内置对象即`ServletContext`，servlet上下文，用于全局共享。

3、将`<context-param>`的键值对放入`ServletContext`即`application`中，`Web应用`内全局共享。

4、读取`<listener>`标签创建监听器，一般会使用`ContextLoaderListener类`，如果使用了`ContextLoaderListener类`，`Spring`就会创建一个`WebApplicationContext类`的对象，`WebApplicationContext类`就是`IoC容器`，`ContextLoaderListener类`创建的`IoC容器`是`根IoC容器`为全局性的，并将其放置在`appication`中，作为应用内全局共享，键名为`WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE`。

5、`listener`创建完成后如果有`<filter>`则会去创建`filter`。

6、初始化创建`<servlet>`，一般使用`DispatchServlet类`。

7、`DispatchServlet`的父类`FrameworkServlet`会重写其父类的`initServletBean`方法，并调用`initWebApplicationContext()`以及`onRefresh()`方法。

8、`initWebApplicationContext()`方法会创建一个当前`servlet`的一个`IoC子容器`，如果存在上述的全局`WebApplicationContext`则将其设置为`父容器`，如果不存在上述全局的则`父容器`为null。

9、读取`<servlet>`标签的`<init-param>`配置的`xml文件`并加载相关`Bean`。

10、`onRefresh()`方法创建`Web应用`相关组件。

### Mybatis中的Dao接口和XML文件里的SQL是如何建立关系的

#### 动态代理

```xml
<bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
    <property name="basePackage" value="com.viewscenes.netsupervisor.dao" />
    <property name="sqlSessionFactoryBeanName" value="sqlSessionFactory"></property>
</bean>
```

简单来说，它就是通过JDK动态代理，返回了一个Dao接口的代理对象，这个代理对象的处理器是`MapperProxy`对象。所以，我们通过`@Autowired`注入Dao接口的时候，注入的就是这个代理对象，我们调用到Dao接口的方法时，则会调用到`MapperProxy`对象的invoke方法。

#### MappedStatement

XML文件中的每一个SQL标签就对应一个MappedStatement对象，这里面有两个属性很重要。

- **id**

全限定类名+方法名组成的ID。

- **sqlSource**

当前SQL标签对应的SqlSource对象。

通过`全限定类名+方法名`找到`MappedStatement`对象，然后解析里面的SQL内容。

#### SqlSource

Mybatis会把每个SQL标签封装成SqlSource对象，根据SQL语句的不同，又分为动态SQL和静态SQL。



通过这三者，将mapper接口与sql语句的调用串联起来。



### Spring 管理事务的实现方式

#### 1、编程式事务管理

#### 2、声明式事务管理— TransactionProxyFactoryBean

#### 3、声明式事务管理—@Transactional

#### 4、Aspectj AOP配置事务

### 动态代理

动态代理相比静态代理，只需要一个类，就可以完成所有实现了接口的类的代理任务，而不需要针对某个特定的类。

利用Proxy.newProxyInstance就可以做到，被代理类必须是实现了某个接口的类，而代理类需要实现InvocationHandler接口。

具体如下：

```java

public class ProxyObject implements InvocationHandler {
    //被代理对象
    Object oj;
    public Object getProxyObject(Object object){
        this.oj = object;
        // 被代理对象的所有接口方法都会被代理
        return Proxy.newProxyInstance(oj.getClass().getClassLoader(),
                                        oj.getClass().getInterfaces(),
                                        this);
    }

    @Override
    // 代理方法，proxy被代理对象，method方法，args方法参数
    // 这里就是在被代理对象的上下插入计时功能
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        Long startTime = System.currentTimeMillis();
        // 通过反射执行方法
        Object result = method.invoke(oj, args);
        Long overTime = System.currentTimeMillis();
        System.out.println(overTime-startTime);
        return result;
    }
}
```

### BeanFactory 和ApplicationContext（Bean工厂和应用上下文）

Bean 工厂（com.springframework.beans.factory.BeanFactory）是Spring 框架最核心的接口，它提供了高级IoC 的配置机制。

应用上下文（com.springframework.context.ApplicationContext）建立在BeanFactory 基础之上。

几乎所有的应用场合我们都直接使用ApplicationContext 而非底层的BeanFactory。

ApplicationContext 的初始化和BeanFactory有一个重大的区别：

- BeanFactory在初始化容器时，并未实例化Bean，直到第一次访问某个Bean 时才实例目标Bean；
- 而ApplicationContext 则在初始化应用上下文时就实例化所有单实例的Bean 。