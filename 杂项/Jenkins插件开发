# Jenkins 插件开发

### 生成jenkins项目

##### 添加Jenkins仓库

修改Maven的settings.xml文件，添加如下：

```xml
<settings>
  <pluginGroups>
    <pluginGroup>org.jenkins-ci.tools</pluginGroup>
  </pluginGroups>
 
  <profiles>
    <!-- Give access to Jenkins plugins -->
    <profile>
      <id>jenkins</id>
      <activation>
        <activeByDefault>true</activeByDefault> <!-- change this to false, if you don't like to have it on per default -->
      </activation>
      <repositories>
        <repository>
          <id>repo.jenkins-ci.org</id>
          <url>https://repo.jenkins-ci.org/public/</url>
        </repository>
      </repositories>
      <pluginRepositories>
        <pluginRepository>
          <id>repo.jenkins-ci.org</id>
          <url>https://repo.jenkins-ci.org/public/</url>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>
  <mirrors>
    <mirror>
      <id>repo.jenkins-ci.org</id>
      <url>https://repo.jenkins-ci.org/public/</url>
      <mirrorOf>m.g.o-public</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```

##### 添加parentPOM

```xml
<parent>
    <groupId>org.jenkins-ci.plugins</groupId>
    <artifactId>plugin</artifactId>
    <version>3.43</version>
</parent>
```

##### 修改属性定制配置项

```xml
<properties>
  <jenkins.version>2.60.1</jenkins.version>
  <java.level>8</java.level>
</properties>
```

###  maven-hpi-plugin

 这是一个Maven插件，用于构建Jenkins插件 。

##### 调试插件

开启单步跟踪

```shell
mvnDebug hpi:run
 
# 或者
export MAVEN_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,address=8000,suspend=n"
mvn hpi:run
```

### 骨架代码



##### 项目结构

类似如下：

![image-20191112095234704](C:\Users\admin\AppData\Roaming\Typora\typora-user-images\image-20191112095234704.png)

重点文件是：QyWechatNotification以及resources下同名文件夹下的config.jelly和global.jelly。

##### Builder、Publisher

QyWechatNotication继承自Publisher，像类似的都需要继承Builder或者是Publisher，实现SimpleBuildStep接口。

SimpleBuildStep是诸如Builder、Publisher之类的Step，可以在构建过程的任何时机调用多次。这些Step应当遵循：

1. 不去实现BuildStep.prebuild方法，因为此方法假设了一种特定的执行顺序
2. 不去实现BuildStep.getProjectActions方法，因为如果此Step不是项目的静态配置的一部分，则它可能永不会被调用
3. 实现BuildStep.getRequiredMonitorService，且返回BuildStepMonitor.NONE，因为只对仅调用一次的Step有意义
4. 不去实现DependencyDeclarer
5. 不假设Executor.currentExecutor为非空，不使用Computer.currentComputer

```java
import hudson.Launcher;
import hudson.Extension;
import hudson.FilePath;
import hudson.util.FormValidation;
import hudson.model.AbstractProject;
import hudson.model.Run;
import hudson.model.TaskListener;
import hudson.tasks.Builder;
import hudson.tasks.BuildStepDescriptor;
import org.kohsuke.stapler.DataBoundConstructor;
import org.kohsuke.stapler.QueryParameter;
 
import javax.servlet.ServletException;
import java.io.IOException;
import jenkins.tasks.SimpleBuildStep;
import org.jenkinsci.Symbol;
import org.kohsuke.stapler.DataBoundSetter;
 
public class HelloWorldBuilder extends Builder implements SimpleBuildStep {
 
    private final String name;
    private boolean useFrench;
 
    // 绑定对象时使用此构造器
    @DataBoundConstructor
    public HelloWorldBuilder(String name) {
        this.name = name;
    }
 
    public String getName() {
        return name;
    }
 
    public boolean isUseFrench() {
        return useFrench;
    }
 
    @DataBoundSetter
    public void setUseFrench(boolean useFrench) {
        this.useFrench = useFrench;
    }
 
    /**
     * SimpleBuildStep的核心方法，执行此Step
     * @param run 此Step所属的Build
     * @param workspace 此Build的工作区，用于文件系统操作
     * @param launcher 用于启动进程
     * @param listener 用于发送输出
     * @throws InterruptedException 如果此Step被中断
     * @throws IOException 出现其它错误，更“礼貌”的错误是AbortException
     */
    public void perform(Run<?, ?> run, FilePath workspace, Launcher launcher, TaskListener listener) throws InterruptedException, IOException {
        if (useFrench) {
            listener.getLogger().println("Bonjour, " + name + "!");
        } else {
            listener.getLogger().println("Hello, " + name + "!");
        }
    }
 
    // 此注解为Jenkins扩展定义唯一的标识符，驼峰式大小写，尽量简短。在流水线脚本中引用此Step时即使用此标识符
    // 标识符不需要全局唯一，只需要在一个扩展点内是唯一的即可
    @Symbol("greet")
    // 标记字段、方法或类，以便Huson能自动发现定位到ExtensionPoint的实现
    @Extension
    // Build / Publisher的描述符
    // Descriptor是可配置实例（Describable）的元数据，也作为Describable的工厂
    public static final class DescriptorImpl extends BuildStepDescriptor<Builder> {
 
        // 校验Project配置表单中的字段
        // 下面的方法检查name字段，参数value注入name的值，可以用@QueryParameter注入其它参数
        // 如果要校验useFrench字段，则需要实现doCheckUsdeFrench方法
        public FormValidation doCheckName(@QueryParameter String value, @QueryParameter boolean useFrench)
                throws IOException, ServletException {
            if (value.length() == 0)
                // 引用资源束
                return FormValidation.error(Messages.HelloWorldBuilder_DescriptorImpl_errors_missingName());
            if (value.length() < 4)
                return FormValidation.warning(Messages.HelloWorldBuilder_DescriptorImpl_warnings_tooShort());
            if (!useFrench && value.matches(".*[éáàç].*")) {
                return FormValidation.warning(Messages.HelloWorldBuilder_DescriptorImpl_warnings_reallyFrench());
            }
            return FormValidation.ok();
        }
 
        // 判断当前Step是否能用于目标类型的项目
        @Override
        public boolean isApplicable(Class<? extends AbstractProject> aClass) {
            return true;
        }
 
        // 此Step的显示名称
        @Override
        public String getDisplayName() {
            return Messages.HelloWorldBuilder_DescriptorImpl_DisplayName();
        }
 
    }
 
}
```

### 可参考资料

jenkins插件开发有很多可以扩展的点，参考下面资料可以深入学习。

博客： https://blog.gmem.cc/jenkins-plugin-development 

github仿照项目： [jenkinsci/qy-wechat-notification-plugin: 企业微信Jenkins构建通知插件](https://github.com/jenkinsci/qy-wechat-notification-plugin) 

bilibili视频： [Jenkins Plugin Development Tutorials, Videos, and More_哔哩哔哩 (゜-゜)つロ 干杯~-bilibili](https://www.bilibili.com/video/av39922366?from=search&seid=7788103341987878187) 

