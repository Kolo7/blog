# tarjan算法

### 作用

寻找有向图中的强连通分量； 
强连通图的定义：图中的每两个点之间互相可达；
强连通分量定义：强连通分量是有向图的极大强连通子图。

### 算法

Tarjan算法是基于对图深度优先搜索的算法，每个强连通分量为搜索树中的一棵子树。搜索时，把当前搜索树中未处理的节点加入一个堆栈，回溯时可以判断栈顶到栈中的节点是否为一个强连通分量。
因为志记的缘故，这里不对算法具体流程做演示，而是简单分析下代码。

### 伪代码

```c++
// 定义DFN(u)为节点u搜索的次序编号(时间戳)，Low(u)为u或u的子树能够追溯到的最早的栈中节点的次序号。
Low(u)=Min
{
    DFN(u),
    Low(v),(u,v)为树枝边，u为v的父节点
    DFN(v),(u,v)为指向栈中节点的后向边(非横叉边)
}
```

```c++
// 当DFN(u)=Low(u)时，以u为根的搜索子树上所有节点是一个强连通分量。

tarjan(u)
{
	DFN[u]=Low[u]=++Index                      // 为节点u设定次序编号和Low初值
	Stack.push(u)                              // 将节点u压入栈中
	for each (u, v) in E                       // 枚举每一条边
		if (v is not visted)               // 如果节点v未被访问过
			tarjan(v)                  // 继续向下找
			Low[u] = min(Low[u], Low[v])
		else if (v in S)                   // 如果节点v还在栈内
			Low[u] = min(Low[u], DFN[v])
	if (DFN[u] == Low[u])                      // 如果节点u是强连通分量的根
		repeat
			v = S.pop                  // 将v退栈，为该强连通分量中一个顶点
			print v
		until (u== v)
}
```

### c++代码

```c++
void tarjan(int i)
{
	int j;
	DFN[i]=LOW[i]=++Dindex;
	instack[i]=true;
	Stap[++Stop]=i;
	for (edge *e=V[i];e;e=e->next)
	{
		j=e->t;
		if (!DFN[j])
		{
			tarjan(j);
			if (LOW[j]<LOW[i])
				LOW[i]=LOW[j];
		}
		else if (instack[j] && DFN[j]<LOW[i])
			LOW[i]=DFN[j];
	}
	if (DFN[i]==LOW[i])
	{
		Bcnt++;
		do
		{
			j=Stap[Stop--];
			instack[j]=false;
			Belong[j]=Bcnt;
		}
		while (j!=i);
	}
}
void solve()
{
	int i;
	Stop=Bcnt=Dindex=0;
	memset(DFN,0,sizeof(DFN));
	for (i=1;i<=N;i++)
		if (!DFN[i])
			tarjan(i);
}
```


### 具体学习链接
[https://byvoid.com/zhs/blog/scc-tarjan/](https://byvoid.com/zhs/blog/scc-tarjan/)
