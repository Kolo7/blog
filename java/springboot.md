# springboot 官方文档解读

## Part Ⅲ. Using Spring Boot

### 13.构建项目

构建系统建议使用Maven。

#### 13.1依赖管理

您不需要为构建配置中的任何这些依赖项提供版本，因为Spring Boot会为您管理这些依赖项。当您升级Spring Boot时，这些依赖项也会以一致的方式升级。

#### 13.2 Maven

Maven用户可以从`spring-boot-starter-parent`项目继承以获得合理的默认值。父项目提供以下功能：

- Java 1.8作为默认编译器级别。
- UTF-8源编码。
- 继承自spring-boot-dependencies pom 的依赖关系管理部分，用于管理公共依赖关系的版本。此依赖关系管理允许您在自己的pom中使用时省略这些依赖项的\<version\>标记。
- 使用执行ID 执行repackage 目标repackage。

`application.properties`和`application.yml`文件接受Spring样式占位符（`${…}`），Maven filtering被更改为使用`@..@`占位符。

##### 13.2.1 继承Starter Parent

```xml
<！ - 继承默认值为Spring Boot  - > 
<parent> 
	<groupId> org.springframework.boot </ groupId> 
	<artifactId> spring-boot-starter-parent </ artifactId> 
	<version> 2.1.7.RELEASE < / version> 
</ parent>
```

通过该设置，您还可以通过覆盖自己项目中的属性来覆盖单个依赖项。

##### 13.2.3 使用Spring Boot Maven插件

Spring Boot包含一个Maven插件，可以将项目打包为可执行jar。<plugins>如果要使用它，请将插件添加到您的 部分，如以下示例所示：

```xml
<build> 
	<plugins> 
		<plugin> 
			<groupId> org.springframework.boot </ groupId> 
			<artifactId> spring-boot-maven-plugin </ artifactId> 
		</ plugin> 
	</ plugins> 
</ build>
```

### 14.构建代码

#### 14.1使用“默认”包

通常不鼓励使用“默认包”。

#### 14.2找到主应用程序类

我们通常建议您将主应用程序类放在其他类之上的根包中。并将`@SpringBootApplication`注解往往放在你的主类。

类似这样的结构：

```xml
com
 +- example
     +- myapplication
         +- Application.java
         |
         +- customer
         |   +- Customer.java
         |   +- CustomerController.java
         |   +- CustomerService.java
         |   +- CustomerRepository.java
         |
         +- order
             +- Order.java
             +- OrderController.java
             +- OrderService.java
             +- OrderRepository.java
```



```java
package com.example.myapplication;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

}
```

### 15.configruition 类

通常建议您的主要源是单个`@Configuration`类。定义`main`方法的类是主要的候选者`@Configuration`。

这也就是说标有`@SpringBootApplication`的类默认是configrution类。

#### 15.1 导入其他configration类

`@Import`注释可以用于导入额外的配置类。或者，您可以使用 `@ComponentScan`自动获取所有Spring组件，导入`@Configuration`类。

#### 15.2导入xml配置

如果您绝对必须使用基于XML的配置，我们建议您仍然从一个`@Configuration`类开始。然后，您可以使用`@ImportResource`注释来加载XML配置文件。

### 16.自动配置

Spring Boot自动配置尝试根据您添加的jar依赖项自动配置Spring应用程序。这个真强。也就是说你不需要创建任何类来使用导入的jar依赖，例如mabatis。

您需要通过向其中一个类添加`@EnableAutoConfiguration`或 `@SpringBootApplication`注释来选择自动配置`@Configuration`。

#### 16.1逐步更换自动配置

自动配置是非侵入性的。在任何时候，您都可以开始定义自己的配置以替换自动配置的特定部分。

#### 16.2禁用特定的自动配置类

如果发现正在应用您不需要的特定自动配置类，则可以使用exclude属性`@EnableAutoConfiguration`禁用它们，如以下示例所示：

```java
import org.springframework.boot.autoconfigure。*;
import org.springframework.boot.autoconfigure.jdbc。*;
import org.springframework.context.annotation。*;

@Configuration 
@EnableAutoConfiguration（exclude = {DataSourceAutoConfiguration.class}）
 public  class MyConfiguration {
}
```

如果类不在类路径中，则可以使用`excludeName`注释的属性并指定完全限定名称。最后，您还可以使用该`spring.autoconfigure.exclude`属性控制要排除的自动配置类列表 。

注：下面这种情况粒度更加细，但是很少用到。

### 17. spring Beans 和依赖注入

您可以自由地使用任何标准的Spring Framework技术来定义bean及其注入的依赖项。使用 `@ComponentScan`（找到你的bean）和使用`@Autowired`（做构造函数注入）效果很好。

如果按照上面的建议构建代码,（也就是启动类在根包中），则可以添加`@ComponentScan`不带任何参数的代码。您的所有应用程序组件（的`@Component`，`@Service`，`@Repository`，`@Controller`等）自动注册为`bean`。

```java
package com.example.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class DatabaseAccountService implements AccountService {

	private final RiskAssessor riskAssessor;

	@Autowired
	public DatabaseAccountService(RiskAssessor riskAssessor) {
		this.riskAssessor = riskAssessor;
	}

	// ...

}
```

如果bean有一个构造函数，则可以省略`@Autowired`，

注：这个地方我怀疑是官网表述不对，可能是说只有一个构造函数，而不是有一个。

注：平时使用setter的似乎更多。

### 18.使用@SpringBootApplication 注解

`@SpringBootApplication`可以使用单个 注释来启用这三个功能，即：

- @EnableAutoConfiguration：启用Spring Boot的自动配置机制
- @ComponentScan：@Component在应用程序所在的包上启用扫描
- @Configuration：允许在上下文中注册额外的bean或导入其他配置类



### 19.运行您的应用程序

将应用程序打包为jar并使用嵌入式HTTP服务器的最大优势之一是，您可以像运行任何其他应用程序一样运行应用程序。调试Spring Boot应用程序也很容易。您不需要任何特殊的IDE插件或扩展。

### 20.开发人员工具

要包含devtools支持，请将模块依赖项添加到您的构建中：

```xml
<dependencies>
	<dependency>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-devtools</artifactId>
		<optional>true</optional>
	</dependency>
</dependencies>
```

#### 20.4 Global Settings

​	您可以通过将名为`.spring-boot-devtools.properties`的文件添加到$ HOME（linux环境变量）文件夹来配置全局devtools设置。

​	添加到此文件的任何属性都适用于计算机上使用devtools的所有Spring Boot应用程序。

暂时就不看了。

### 21.包装您的生产应用程序

啥也没有

## IV. Spring Boot features

### 23. SpringApplication

这一节主要介绍启动信息的定制。

#### 23.1 启动失败

如果您的应用程序无法启动，则已注册`FailureAnalyzers`有机会提供专用错误消息和具体操作来解决问题。

Spring Boot提供了许多`FailureAnalyzer`实现，您可以 添加自己的实现。（在第76.1节介绍）

如果没有故障分析器能够处理异常，您仍然可以显示完整的条件报告，以便更好地了解出现了什么问题。只需启用 `debug` 属性或者是启动`debug`日志，通过`org.springframework.boot.autoconfigure.logging.ConditionEvaluationReportLoggingListener`（在<a href="#24.外部化配置">24.外部化配置</a>介绍如何启用）。

#### 23.2自定义启动消息

通过在类路径下添加`banner.txt`文件或者是指定`spring.banner.location`属性设置为banner文件的位置，更改启动时打印的横幅。

如果文件的编码不是UTF-8，则可以进行设置`spring.banner.charset`更改编码方式。

除了一个文本文件，你还可以添加一个`banner.gif`，`banner.jpg`或`banner.png` 图像文件到类路径，或者是设置`spring.banner.image.location`属性。该图片将会转换为ASCII字符表示，打印在启动时的最上方。

在`banner.txt`文件中，您可以使用以下任何占位符：

| Variable                                                     | Description                                              |
| ------------------------------------------------------------ | -------------------------------------------------------- |
| `${application.version}`                                     | 应用程序的版本号                                         |
| `${application.formatted-version}`                           | 应用程序的版本号（用括号括起来并以前缀为例`v`）          |
| `${spring-boot.version}`                                     | 您正在使用的Spring Boot版本                              |
| `${spring-boot.formatted-version}`                           | 您正在使用的Spring Boot版本（用括号括起来并带有前缀`v`） |
| `${Ansi.NAME}` (or `${AnsiColor.NAME}`, `${AnsiBackground.NAME}`, `${AnsiStyle.NAME}`) | ANSI转义码的名称在哪里。（搞不懂）                       |
| `${application.title}`                                       | 申请的标题                                               |

`SpringApplication.setBanner(…)`：如果要以编程方式生成横幅，则可以使用该方法。

使用`org.springframework.boot.Banner`接口并实现自己的`printBanner()`方法。（这一般没必要吧）

您还可以使用该`spring.main.banner-mode`属性来确定是否必须在`System.out`（`console`）上打印横幅，发送到配置的日志（`log`），或者根本不生成横幅（`off`）。

打印的横幅在spring容器中被注册为单例Bean：`springBootBanner`。

关闭横幅：

```yaml
spring:
	main:
		banner-mode: "off"
```

#### 23.3自定义SpringApplication

如果`SpringApplication`默认值不符合您的要求，您可以改为创建本地实例并对其进行自定义。

类似这种：

```java
public static void main(String[] args) {
	SpringApplication app = new SpringApplication(MySpringConfiguration.class);
	app.setBannerMode(Banner.Mode.OFF);
	app.run(args);
}
```

很明显这种方式和使用springBoot的初衷不符。

一般使用application.properties配置或者是application.yaml文件配置。（具体参考<a href="#24.外部化配置">24.外部化配置</a>）

[`SpringApplication`Javadoc](https://docs.spring.io/spring-boot/docs/2.1.7.RELEASE/api/org/springframework/boot/SpringApplication.html)

#### 23.4 Fluent Builder API

如果更喜欢使用Fluent构建器。

```java
new SpringApplicationBuilder()
		.sources(Parent.class)
		.child(Application.class)
		.bannerMode(Banner.Mode.OFF)
		.run(args);
```



#### 23.5应用程序事件和监听器

`SpringApplication`发送一些额外的应用程序事件。

应用程序运行时，应按以下顺序发送应用程序事件：

1. `ApplicationStartingEvent`是在一个运行的开始，但任何处理之前被发送，除了listeners 和initializers的注册。
2. `ApplicationEnvironmentPreparedEvent`当被发送`Environment`到中已知的上下文中使用，但是在创建上下文之前。
3. `ApplicationPreparedEvent`刷新开始前，刚刚发，但之后的bean定义已经被加载。
4. `ApplicationStartedEvent`上下文已被刷新后发送，但是任何应用程序和命令行 runners 都被调用前。
5. `ApplicationReadyEvent`任何应用程序和命令行 runners 被呼叫后发送。它表示应用程序已准备好为请求提供服务。
6. `ApplicationFailedEvent`如果在启动时异常发送。

#### 23.6Web Environment

SpringApplication会自动判断，来确定合适的WebApplicationType。

- 如果存在Spring MVC，则为`AnnotationConfigServletWebServerApplicationContext`
- 如果Spring MVC不存在且存在Spring WebFlux，则为`AnnotationConfigReactiveWebServerApplicationContext`
- 否则，是`AnnotationConfigApplicationContext`

您可以通过调用`setWebApplicationType(WebApplicationType)`覆盖默认类型。

#### 23.7访问应用程序参数

如果需要访问传递给的应用程序参数，`SpringApplication.run(…)`可以传参`org.springframework.boot.ApplicationArguments`。

```java
import org.springframework.boot.*;
import org.springframework.beans.factory.annotation.*;
import org.springframework.stereotype.*;

@Component
public class MyBean {

	@Autowired
	public MyBean(ApplicationArguments args) {
		boolean debug = args.containsOption("debug");
		List<String> files = args.getNonOptionArgs();
		// if run with "--debug logfile.txt" debug=true, files=["logfile.txt"]
	}

}
```

#### 23.8使用ApplicationRunner或CommandLineRunner

如果您需要在启动`SpringApplication`后运行某些特定代码，则可以实现`ApplicationRunner`或`CommandLineRunner`接口。两个接口以相同的方式工作并提供一个`run`方法，该方法在`SpringApplication.run(…)`完成之前调用 。

```java
import org.springframework.boot.*;
import org.springframework.stereotype.*;

@Component
public class MyBean implements CommandLineRunner {

	public void run(String... args) {
		// Do something...
	}

}
```

如果需要按顺序调用多个特定代码，可以额外实现 `org.springframework.core.Ordered`接口或使用`org.springframework.core.annotation.Order`注释。

#### 23.9申请退出

 如果希望调用`SpringApplication.exit()`返回特定的退出代码，则可以实现接口`org.springframework.boot.ExitCodeGenerator`。然后可以传递此退出代码给`System.exit()`，以将其作为状态代码返回。

```java
@SpringBootApplication
public class ExitCodeApplication {

	@Bean
	public ExitCodeGenerator exitCodeGenerator() {
		return () -> 42;
	}

	public static void main(String[] args) {
		System.exit(SpringApplication.exit(SpringApplication.run(ExitCodeApplication.class, args)));
	}

}
```

#### 23.10管理员功能

通过指定`spring.application.admin.enabled`为应用程序启用与管理相关的功能。这将暴露`SpringApplicationAdminMXBean`。您可以使用此功能远程管理Spring Boot应用程序。

### 24.外部化配置

Spring Boot允许在外部化配置。以便可以在不同的环境中使用相同的应用程序代码。可以使用 properties文件，YAML 文件， environment variables（环境变量），和命令行参数来外部化配置。属性值可以通过直接注入到Bean中（通过@Value注解），或者通过`@ConfigurationProperties`绑定到结构化对象。

Spring Boot使用一种非常特殊的`PropertySource`顺序，旨在允许合理地覆盖值。按以下顺序考虑属性：

1. Devtools 主目录上的全局设置属性，只有当devtools处于活动状态才适用。
2. `@TestPropertySource` 你的测试注释。
3. `properties`属性测试，`@SpringBootTest`。
4. 命令行参数。
5. 来自`SPRING_APPLICATION_JSON`的属性（在环境变量或系统属性中的内联JSON）。
6. `ServletConfig` init参数。
7. `ServletContext` init参数。
8. 来自`java:comp/env`的JNDI属性。
9. Java系统属性（`System.getProperties()`）。
10. OS环境变量。
11. `RandomValuePropertySource`，只有在拥有属性random.*时生效。
12. properties和YAML文件（在jar包之外的，命名为application-{profile}.properties或是application-{profile}.yaml）。
13. properties和YAML（在jar包之内的，命名为application-{profile}.properties或是application-{profile}.yaml）。
14. properties和YAML文件（在jar包之外的，命名为application.properties或是application.yaml）。
15. properties和YAML文件（在jar包之内的，命名为application.properties或是application.yaml）。
16. 注释在`@Configuration`类上面的 `@PropertySource`。
17. 默认属性（由指定`SpringApplication.setDefaultProperties`设置）。

在程序中使用属性的示例：

```java
import org.springframework.stereotype.*;
import org.springframework.beans.factory.annotation.*;
@Component
public class MyBean {
    @Value("${name}")
    private String name;
}
```

#### 24.1配置随机值

`RandomValuePropertySource`对于注入随机值很有用，它可以生成整数，长整数，uuids或字符串，示例：

```properties
my.secret=${random.value}
my.number=${random.int}
my.bignumber=${random.long}
my.uuid=${random.uuid}
my.number.less.than.ten=${random.int(10)}
my.number.in.range=${random.int[1024,65536]}
```

`random.int`有两种语法，指定一个值那么就是随机的最大值，指定两个值就是随机范围。

#### 24.2访问命令行属性

默认情况下，`SpringApplication`将任何命令行选项参数的`property`添加到spring环境中，命令行属性的优先级很高。

如果您不希望将命令行属性添加到`Environment`，则可以使用`SpringApplication.setAddCommandLineProperties(false)`禁用它们。

#### 24.3应用程序属性文件

`SpringApplication`从以下位置的`application.properties`文件加载属性并将它们添加到Spring `Environment`。

1. 当前目录的一个`/config`子目录
2. 当前目录
3. 一个classpath `/config`包
4. 类路径中的根

列表按优先级排序（在列表中较高位置定义的属性将覆盖在较低位置中定义的属性）。

可以使用`yaml`替代`properties`文件。

对于 application.properties 而言，它不一定非要叫 application ，但是，需要明确指定配置文件的文件名。

在命令行启动时，加入参数`spring.config.name=app`，那么就会去读取名称为`app.properties`或是`app.yaml`的配置文件了。

还可以使用`spring.config.location`environment属性（以逗号分隔的目录位置或文件路径列表）来引用显式位置。以下示例显示如何指定其他文件名：

```sh
$ java -jar myproject.jar --spring.config.name = app
```

以下示例显示如何指定两个位置：

```shell
$ java -jar myproject.jar --spring.config.location = classpath：/default.properties,classpath：/override.properties
```

如果`spring.config.location`包含目录（而不是文件），它们应该以`/`结束。

`spring.config.additional-location`使用自定义配置位置，除了默认位置之外，还会在自定义配置位置搜索。

自定义配置位置的配置文件可以覆盖默认位置的配置文件。



#### 24.4特定于配置文件的属性

​	配置文件的名字除了`application.properties`之外，还可以定义为`application-{profile}.properties`。如果没有配置文件，那么springboot将会加载默认的配置文件`application-default.properties`加载属性。

​	无论配置文件的位置在哪，配置文件的属性都会覆盖默认配置文件的属性。

​	如果指定多个配置文件，那么最后应用的配置将会生效。

#### 24.5属性中的占位符

`application.properties`中的属性将会加入到应用上下文中，使用占位符可以引用：

```properties
app.name=MyApp
app.description=${app.name} is a Spring Boot application
```

#### 24.6加密属性

没有任何支持，具体看后续。

#### 24.7使用YAML而不是属性

​	SpringApplication自动支持YAML替代`properties`。

##### 24.7.1加载YAML

​	可以使用`@ConfigurationProperties`将配置文件的属性读取并自动封装成一个实体类。

```properties
connection.username=admin
connection.password=kyjufskifas2jsfs
connection.remoteAddress=192.168.1.1
```

```java
@Component
@ConfigurationProperties(prefix="connection")
@Data
public class ConnectionSettings {
    private String username;
    private String remoteAddress;
    private String password ;
}
```

##### 24.7.2在Spring环境中公开YAML作为属性

可以通过@Value和占位符`${}`来访问YAML属性。

##### 24.7.3多环境配置切换

可以同时在一个或者多个文件中配置不同属性，以便于在开发环境，线上环境切换配置。

使用`spring.profiles`来设置name，`spring.profiles.active`来开启对应name的配置：

单文件配置切换

```yaml
spring:
  profiles:
    active: dev
    
---
# dev环境配置
spring:
  profiles: dev
  
---
# test环境配置
spring:
  profiles: test
  
---
# production
spring:
  profiles: production
```

使用`---`分隔不同的部分，第一部分是通用配置，也可以不使用通用配置，而是在jar启动的使用配置参数`--spring.profiles.active=test`。

多文件配置切换

可以添加 4 个配置文件：

- `applcation.yml` - 公共配置
- `application-dev.yml` - 开发环境配置
- `application-test.yml` - 测试环境配置
- `application-prod.yml` - 生产环境配置

在 `applcation.yml` 文件中可以通过以下配置来激活 profile：

```yaml
spring:
  profiles:
    active: prod
```

##### 24.7.4 YAML缺点

无法通过`@PropertySource`注解来加载YAML文件，必须使用`properties`文件。

不要在一个yaml文件下配置多环境配置同时又使用多yaml文件切换配置，会产生不可预料的错误。

### 24.8类型安全配置属性

有时使用`@Value(${property})`来一个一个的获取配置属性会显得效率很低。Spring Boot提供了一种使用属性的替代方法，该方法允许强类型bean管理和验证应用程序的配置，如以下示例所示：

```java
@ConfigurationProperties("acme")
public class AcmeProperties {
	private boolean enabled;
	private InetAddress remoteAddress;
	private final Security security = new Security();
	public boolean isEnabled() { ... }
	public void setEnabled(boolean enabled) { ... }
	public InetAddress getRemoteAddress() { ... }
	public void setRemoteAddress(InetAddress remoteAddress) { ... }
	public Security getSecurity() { ... }
	public static class Security {
		private String username;
		private String password;
		private List<String> roles = new ArrayList<>(Collections.singleton("USER"));
		public String getUsername() { ... }
		public void setUsername(String username) { ... }
		public String getPassword() { ... }
		public void setPassword(String password) { ... }
		public List<String> getRoles() { ... }
		public void setRoles(List<String> roles) { ... }

	}
}
```

#### 24.8.1第三方配置

`@ConfigurationProperties`除了用于注释类之外，您还可以在公共`@Bean`方法上使用它。

```java
@ConfigurationProperties（prefix =“another”）
@Bean
 public AnotherComponent anotherComponent（）{
	...
}
```

#### 24.8.2 宽松绑定

Spring Boot使用一些宽松的规则来绑定bean的`Environment`属性，不需要配置属性和bean属性名完全一致。

常见示例包括破折号分隔的环境属性和大写环境属性。这都是自动完成的功能，不需要额外的配置。

大体来说，properties文件和yaml文件都支持自动转换以下：

- 驼峰命名法
- kebab命名（就是用-分隔）
- 下划线表示法

#### 24.8.3合并复杂类型

当同名配置在多个配置文件中出现，并且存在List、Map配置，那么将会采用覆盖替换的方式，而不是合并多个配置。将使用具有最高优先级的配置文件。

#### 24.8.4属性转换

一般使用情况是，字符串转化为日期类、数据大小类。

这一块使用情况似乎很少见。

#### 24.8.5@ConfigurationProperties验证

Spring Boot尝试在`@ConfigurationProperties`使用Spring的`@Validated`注释装配时验证类。

注：@Validated 注释在方法参数上，表示对参数进行校验，还可以开启分组检验。

当spring容器装配AcmeProperties类时，将会验证属性。

也可以使用`@Bean`配合`@Validated`。

如果存在嵌套验证，那么就要使用`@Valid`注解。

```java
@ConfigurationProperties(prefix="acme")
@Validated
public class AcmeProperties {
	@NotNull
	private InetAddress remoteAddress;
}
```

### 25. Profiles

Spring Profiles提供了一种隔离应用程序配置部分并使其仅在特定环境中可用的方法。

使用@Profile配合@Component或者是@Configuration，可以在指定spring.profiles.active生效情况下才加载Bean或是配置类，例如：

```java
@Configuration
@Profile("production")
public class ProductionConfiguration {
}
```

只有当以下配置生效时，上面的配置类才会加载

```properties
spring.profiles.active=production
```

#### 25.1添加活动配置文件

`spring.profiles.include`属性可用于无条件添加活动配置文件。例如，当开启下面配置的时候，`proddb`和`prodmq`配置也同时生效：

```yaml
--- 
my:
  property: fromyamlfile
 --- 
spring:
  profiles: PROD
 spring:
   profiles:
     include: proddb,prodmq
```

#### 25.2以编程方式设置配置文件

`SpringApplication.setAdditionalProfiles(…)`在应用程序运行之前通过调用以编程方式设置活动配置文件。

#### 25.3Profile-specific Configuration Files

这个不好翻译，但是是在说明前面提到的`@ConfigurationProperties`，可以加载指定名称的多个配置。可以参考<a href="#24.4特定于配置文件的属性">24.4特定于配置文件的属性</a>。

### 26. 日志

Spring Boot为[Java Util Logging](https://docs.oracle.com/javase/8/docs/api//java/util/logging/package-summary.html)，[Log4J2](https://logging.apache.org/log4j/2.x/)和 [Logback](https://logback.qos.ch/)提供了默认配置 。在每种情况下，记录器都预先配置为使用控制台输出，同时还提供可选的文件输出。

通常，您不需要更改日志记录依赖项，并且Spring Boot默认值可以正常工作。

#### 26.1日志格式

输出以下项目：

- 日期和时间：毫秒精度，易于排序。
- 日志级别：`ERROR`，`WARN`，`INFO`，`DEBUG`，或`TRACE`。
- 进程ID。
- 一个`---`分离器来区分实际日志消息的开始。
- 线程名称：用方括号括起来（可能会截断控制台输出）。
- 记录器名称：这通常是记录所在类名称（通常缩写）。
- 日志消息。

#### 26.2控制台输出

默认日志配置会在写入时将消息回显到控制台。默认情况下，会记录`ERROR`-level，`WARN`-level和`INFO`-level消息。还可以通过使用`--debug`标志启动应用程序来启用“调试”模式。

```shell
$ java -jar myapp.jar --debug
```

启用调试模式后，将输出更多信息或。

可以通过使用`--trace`，启动应用程序来启用“跟踪”模式。做可以启用跟踪日志记录。

##### 26.2.1彩色编码输出

可以设置 `spring.output.ansi.enabled`为支持的值覆盖成为彩色的字体。

转换器根据日志级别为输出着色。

| Level   | Color  |
| ------- | ------ |
| `FATAL` | Red    |
| `ERROR` | Red    |
| `WARN`  | Yellow |
| `INFO`  | Green  |
| `DEBUG` | Green  |
| `TRACE` | Green  |

#### 26.3文件输出

默认情况下，Spring Boot仅记录到控制台，不会写入日志文件。如果要输出到日志文件，则需要设置 `logging.file`或`logging.path`属性。

| `logging.file` | `logging.path` | Example    | Description                                                  |
| -------------- | -------------- | ---------- | ------------------------------------------------------------ |
| *(none)*       | *(none)*       |            | 输出到控制台                                                 |
| 指定文件名     | *(none)*       | `my.log`   | 输出到指定文件。名称可以是相对位置或是绝对路径。             |
| *(none)*       | 指定文件名     | `/var/log` | 写入到指定文件夹下的 `spring.log`日志文件 。 名称可以是相对路径或绝对路径 |

日志文件在达到10 MB时会轮换，与控制台输出一样。默认情况下会记录`ERROR`-level， `WARN`-level和`INFO`-level消息。可以使用`logging.file.max-size`属性更改大小限制。除非`logging.file.max-history`已设置属性，否则以前轮换的文件将永久归档。

#### 26.4日志级别

可以通过设置，使得只有对应级别的日志才能输出出来，其他的将不会输出。在`application.properties`文件中加入：

```properties
logging.level.root = WARN
 logging.level.org.springframework.web = DEBUG
 logging.level.org.hibernate = ERROR
```

#### 26.5日志组

将相关的记录器组合在一起以便可以同时配置它们。例如，将所有tomcat服务器的包加入到同一个组，以便同时配置：

```properties
logging.group.tomcat=org.apache.catalina, org.apache.coyote, org.apache.tomcat
```

定义后，您可以使用一行更改组中所有记录器的级别：

```properties
logging.level.tomcat=TRACE
```

Spring Boot包含以下预定义的日志记录组，可以直接使用：

| Name | Loggers                                                      |
| ---- | ------------------------------------------------------------ |
| web  | `org.springframework.core.codec`, `org.springframework.http`, `org.springframework.web` |
| sql  | `org.springframework.jdbc.core`, `org.hibernate.SQL`         |

#### 26.6自定义日志配置

可以通过在类路径中包含对应的包激活各种日志系统，并且可以在类路径或者是指定位置下配置不同配置文件进一步自定义日志。

可以使用`org.springframework.boot.logging.LoggingSystem`系统属性强制Spring Boot使用特定的日志记录系统 。该配置项应该是一个继承了`LoggingSystem`接口的类的全限定类名。还可以使用`none`完全禁止Spring boot的日志记录配置。

根据日志记录系统，将加载以下文件：

| Logging System          | Customization                                                |
| ----------------------- | ------------------------------------------------------------ |
| Logback                 | `logback-spring.xml`, `logback-spring.groovy`, `logback.xml`, or `logback.groovy` |
| Log4j2                  | `log4j2-spring.xml` or `log4j2.xml`                          |
| JDK (Java Util Logging) | `logging.properties`                                         |

官方建议：不要使用Java Util Logging，并且日志配置文件名最好是使用类似`logback-spring.xml`这种`-spring`形式。

在spring的配置 文件中也可以对日志的属性进行配置，它们在系统中有对应的属性：

| Spring Environment                  | System Property                 | Comments                                                     |
| ----------------------------------- | ------------------------------- | ------------------------------------------------------------ |
| `logging.exception-conversion-word` | `LOG_EXCEPTION_CONVERSION_WORD` | 日志异常时使用的转换字。                                     |
| `logging.file`                      | `LOG_FILE`                      | 定义输出日志文件                                             |
| `logging.file.max-size`             | `LOG_FILE_MAX_SIZE`             | 最大日志文件大小（如果启用了LOG_FILE）。（仅支持默认的Logback设置。） |
| `logging.file.max-history`          | `LOG_FILE_MAX_HISTORY`          | 要保留的最大归档日志文件数（如果启用了LOG_FILE）。（仅支持默认的Logback设置。） |
| `logging.path`                      | `LOG_PATH`                      | 输入日志文件的指定路径                                       |
| `logging.pattern.console`           | `CONSOLE_LOG_PATTERN`           | 输出到控制台的日志的格式                                     |
| `logging.pattern.dateformat`        | `LOG_DATEFORMAT_PATTERN`        | 输出日志中日期的格式                                         |
| `logging.pattern.file`              | `FILE_LOG_PATTERN`              | 要在文件中使用的日志模式（如果`LOG_FILE`已启用）。（仅支持默认的Logback设置。） |
| `logging.pattern.level`             | `LOG_LEVEL_PATTERN`             | 呈现日志级别时使用的格式（默认`%5p`）。（仅支持默认的Logback设置。） |
| `PID`                               | `PID`                           | 当前进程ID（如果可能，则在未定义为OS环境变量时发现）。       |

####  26.7Logback 扩展

这一部分，暂不查看了。

Spring Boot包含许多Logback扩展，可以帮助进行高级配置。您可以在`logback-spring.xml`配置文件中使用这些扩展名。

> 由于标准`logback.xml`配置文件加载过早，因此无法在其中使用扩展。您需要使用`logback-spring.xml`或定义 `logging.config`属性。

> 扩展不能与Logback的 配置扫描一起使用。

### 27. 国际化

Springboot支持本地化消息，这样您的应用程序就可以满足不同语言首选项的用户。默认情况下，Springboot会在类路径的根目录中查找消息资源。

### 28. JSON

默认配置。

### 29. 开发Web应用程序

加入依赖`spring-boot-starter-web`或者是`spring-boot-starter-webflux`构建响应式Web应用程序。

#### 29.1 SpringMVC



```java
@RestController
@RequestMapping(value="/users")
public class MyRestController {

	@RequestMapping(value="/\{user}", method=RequestMethod.GET)
	public User getUser(@PathVariable Long user) {
		// ...
	}

	@RequestMapping(value="/\{user}/customers", method=RequestMethod.GET)
	List<Customer> getUserCustomers(@PathVariable Long user) {
		// ...
	}

	@RequestMapping(value="/\{user}", method=RequestMethod.DELETE)
	public User deleteUser(@PathVariable Long user) {
		// ...
	}

}
```

##### 29.1.1 Spring MVC自动配置

自动配置在Spring的默认值之上添加了以下功能：

- 包含`ContentNegotiatingViewResolver`和`BeanNameViewResolver`Bean类。
- 支持提供静态资源，包括对WebJars的支持。
- 自动注册`Converter`，`GenericConverter`和`Formatter`Bean类。
- 支持`HttpMessageConverters`。
- 自动注册`MessageCodesResolver`。
- 支持静态`index.html`。
- 支持自定义`Favicon`。
- 自动使用`ConfigurableWebBindingInitializer`bean。

如果您想保留Spring Boot MVC功能并且想要添加其他 MVC配置，可以添加自己的`@Configuration`类类型 `WebMvcConfigurer`。

如果希望自定义实例`RequestMappingHandlerMapping`、`RequestMappingHandlerAdapter`、`ExceptionHandlerExceptionResolver`，可以声明`WebMvcRegistrationsAdapter` 实例以提供此类组件，

如果您想完全控制Spring MVC，可以添加自己的`@Configuration` 注释`@EnableWebMvc`。

##### 29.1.2 HttpMessageConverters

Spring MVC使用该`HttpMessageConverter`接口来转换HTTP请求和响应。默认情况下，字符串是以编码的`UTF-8`。

如果需要添加或自定义转换器，可以使用Spring Boot的 `HttpMessageConverters`类，如下面的列表所示：

```java
import org.springframework.boot.autoconfigure.http.HttpMessageConverters;
import org.springframework.context.annotation.*;
import org.springframework.http.converter.*;

@Configuration
public class MyConfiguration {
	@Bean
	public HttpMessageConverters customConverters() {
		HttpMessageConverter<?> additional = ...
		HttpMessageConverter<?> another = ...
		return new HttpMessageConverters(additional, another);
	}
}
```

至于如何自定义自己的HttpMessageConverter实现类，这里并没有说。

##### 29.1.3自定义JSON序列化程序和反序列化程序

如果希望编写自己的类`JsonSerializer`和`JsonDeserializer`类。Spring Boot提供了一种`@JsonComponent`注释，可以更容易地直接注册Spring Beans。

可以`@JsonComponent`直接使用注释`JsonSerializer`或 `JsonDeserializer`实现。还可以在包含序列化类，作为内部类的类上使用它。

```java
@JsonComponent
public class Example {
	public static class Serializer extends JsonSerializer<SomeObject> {
		// ...
	}
	public static class Deserializer extends JsonDeserializer<SomeObject> {
		// ...
	}
}
```

所有注解`@JsonComponent`Bean类会通过`ApplicationContext`在Jackson自动注册。通用的组件扫描规则对`@JsonComponent`同样适用。

##### 29.1.4 MessageCodesResolver

Spring MVC有一个生成错误代码的策略，用于从绑定错误中呈现错误消息：`MessageCodesResolver`。

##### 29.1.5静态内容

默认情况下，Spring Boot从类路径中的`/static`（ `/public`或`/resources`或`/META-INF/resources`）目录或者根目录中提供静态内容`ServletContext`。

Spring MVC使用`ResourceHttpRequestHandler`，以便可以添加自己`WebMvcConfigurer`或者覆盖`addResourceHandlers`方法来修改默认行为。

Spring总是通过它来处理请求 `DispatcherServlet`。

默认情况下，会映射资源`/**`，但可以使用该`spring.mvc.static-path-pattern`属性对其进行调整 。例如，重新定位所有资源 `/resources/**`可以实现如下：

```properties
spring.mvc.static-path-pattern = / resources / **
```

##### 29.1.6欢迎页面

Spring Boot在配置的静态内容位置中查找`index.html`文件，

##### 29.1.7自定义Favicon

自动查找配置的静态内容位置和类路径的根查找，。如果存在这样的文件，它将自动用作应用程序的favicon。

##### 29.1.8路径匹配和内容协商

Spring Boot默认选择禁用后缀模式匹配，也就是不会忽略后缀进行匹配。

如果您了解警告并仍希望您的应用程序使用后缀模式匹配，则需要以下配置：

```properties
spring.mvc.contentnegotiation.favor-path-extension=true
spring.mvc.pathmatch.use-suffix-pattern=true
```

或者，不是打开所有后缀模式，而是仅支持已注册的后缀模式更安全：

```properties
spring.mvc.contentnegotiation.favor-path-extension=true
spring.mvc.pathmatch.use-registered-suffix-pattern=true
```

##### 29.1.9 ConfigurableWebBindingInitializer

Spring MVC使用`WebBindingInitializer`来初始化`WebDataBinder`特定请求。果你自己创建`ConfigurableWebBindingInitializer` `@Bean`，Spring Boot会自动配置Spring MVC来使用它。

##### 29.1.10模板引擎

Spring MVC支持各种模板技术，包括Thymeleaf，FreeMarker和JSP。

应该避免使用JSP。

##### 29.1.11错误处理

默认的，spring boot提供了一个/error映射，它以合理的方式处理所有错误，并在servlet容器中将其注册为“全局”错误页。

要完全替换默认行为，可以实现`ErrorController` 并注册该类型的bean，或者添加`ErrorAttributes` 类型的bean以使用现有机制，但替换内容。

使用注解`@ControllerAdvice`可以将来自Controller层进行全局处理，而不需要手动捕获。

```java
@ControllerAdvice(basePackageClasses = AcmeController.class)
public class AcmeControllerAdvice extends ResponseEntityExceptionHandler {

	@ExceptionHandler(YourException.class)
	@ResponseBody
	ResponseEntity<?> handleControllerException(HttpServletRequest request, Throwable ex) {
		HttpStatus status = getStatus(request);
		return new ResponseEntity<>(new CustomErrorType(status.value(), ex.getMessage()), status);
	}

	private HttpStatus getStatus(HttpServletRequest request) {
		Integer statusCode = (Integer) request.getAttribute("javax.servlet.error.status_code");
		if (statusCode == null) {
			return HttpStatus.INTERNAL_SERVER_ERROR;
		}
		return HttpStatus.valueOf(statusCode);
	}

}
```

**自定义错误页面**

如果要显示给定状态代码的自定义HTML错误页面，可以将文件添加到`/error`文件夹下。

```
src/
 +- main/
     +- java/
     |   + <source code>
     +- resources/
         +- templates/
             +- error/
             |   +- 5xx.ftl
             +- <other templates>
```

