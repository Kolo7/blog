@PostConstruct 延迟初始化（在@Autowired和构造方法之后执行）
@Value（注入peroperties文件中的属性）
@ConfigurationProperties(prefix="")（相当于将Value的组合使用，将注入的多个属性配成一个类的字段，按名注入，注意要写setter、getter方法）
@ComponentScan（开启扫描，就可以使用@Commont注解了）
@Configration 对类进行一些装配操作生成bean
@Bean(name="") 给Bean取名，配合@Resource使用
@Resource byName方式注入

### 条件实例化

@ConditionalOnBean（仅仅在当前上下文中存在某个对象时，才会实例化一个Bean）
@ConditionalOnClass（某个class位于类路径上，才会实例化一个Bean）
@ConditionalOnExpression（当表达式为true的时候，才会实例化一个Bean）
@ConditionalOnMissingBean（仅仅在当前上下文中不存在某个对象时，才会实例化一个Bean）
@ConditionalOnMissingClass（某个class类路径上不存在的时候，才会实例化一个Bean）
@ConditionalOnNotWebApplication（不是web应用）
@ConditionalOnProperty(name="propertyName", havingValue="true")（当某个proerty为true的时候才会实例化一个Bean）

### 线程池

@EnableAsync （启用SpringBoot自带的线程池）

```java
@Configuration
@ConfigurationProperties(prefix = "task.pool")
@EnableAsync
public class ThreadPoolConfigration {
    private int corePoolSize;

    private int maxPoolSize;

    private int keepAliveSeconds;

    private int queueCapacity;

    @Bean
    public Executor myTaskAsyncPool() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        //核心线程池大小
        executor.setCorePoolSize(corePoolSize);
        //最大线程数
        executor.setMaxPoolSize(maxPoolSize);
        //队列容量
        executor.setQueueCapacity(queueCapacity);
        //活跃时间
        executor.setKeepAliveSeconds(keepAliveSeconds);
        //线程名字前缀
        executor.setThreadNamePrefix("MyExecutor-");

        // setRejectedExecutionHandler：当pool已经达到max size的时候，如何处理新任务
        // CallerRunsPolicy：不在新线程中执行任务，而是由调用者所在的线程来执行
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        executor.initialize();
        return executor;
    }
	// 省略一堆getter、setter方法
}
```

@Async("myTaskAsyncPool") 配合该注解方法，方法在调用时自动使用线程池中多线程执行。

### SpringBoot+Junit

@RunWith(SpringRunner.class)
@SpringBootTest
@WebAppConfiguration
三者组合使用进行测试