# lombok和fastJSON

### lombok

#####  @Getter、@Setter 

1. `@Getter`声明创建getter方法；
2. `@Setter`声明创建setter方法；

##### @ToString

 简单使用即可。

##### @EqualsAndHashCode

自动生成`equels`方法和`HashCode`方法

##### @NoArgsConstructor

自动生成无参构造方法。

如果配合`@NotNull`使用，将会自动忽略掉`@NotNull`

#####  @RequiredArgsConstructor

将会为标注有`@NotNull`的字段自动生成构造方法。

##### @AllArgsConstructor

生成一个初始化所有字段的构造方法。

##### @Data

 `@Data`是一个集合体。包含`Getter`,`Setter`,`RequiredArgsConstructor`,`ToString`,`EqualsAndHashCode` 

##### @Value

 生成一个不可变对象， 对于所有的字段都将生成final。

  `@Value`是一个集合体。包含`Getter`,`AllArgsConstructor`,`ToString`,`EqualsAndHashCode`。 

##### @Build

将会生成Build方法，复制自身，生成一个一样的新对象。

`@Build`是一个集合体，包含了`Getter`,`Setter`,`RequiredArgsConstructor`,`ToString`,`EqualsAndHashCode` ,`Build`。

### fastJSON

