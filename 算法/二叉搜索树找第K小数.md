# 二叉搜索树找第k小数

### 题面

给定一棵二叉搜索树，请找出其中的第k小的结点。例如， （5，3，7，2，4，6，8）    中，按结点数值大小顺序第三小结点的值为4。

### 分析

​	这类似于一个经典题目，在一个无序的数组中查找第k大数。这个经典题目的常见解法有排序后直接找，但这不适用于该题。还有个解法就是类似于快速排序，每次找到一个数，定好位，让这个数左边的数都比它小，右边的都比它大，如果k比左边数的个数小，那么可以确定第k大数在左边，反之在右边，递归下去，很快就能找到。这是O(N*K)的复杂度，而K是一个常数，所以就是O(n)的时间复杂度。

​	这道题可以借鉴上面的方法，二叉搜索树的特性就是满足：结点的左子树的节点都比自身小，右子树的节点都比自身大。因此就可以用上面的方法了。

### 代码

​	因为是牛客网上剑指offer的题，所以结构看起来怪怪的，无伤大雅，思路是体现出来了的。

```java
/*
public class TreeNode {
    int val = 0;
    TreeNode left = null;
    TreeNode right = null;

    public TreeNode(int val) {
        this.val = val;

    }

}
*/
public class Solution {
    TreeNode KthNode(TreeNode pRoot, int k)
    {
        if(pRoot==null) return null;
        CalNode cRoot = afterOrder(pRoot);
        if(k<=0 ||k>cRoot.calLeft+cRoot.calRight+1) return null;
        return searchNoK(cRoot, k);
    }

    TreeNode searchNoK(CalNode head, int k){
        int calLeft = head.calLeft;
        int calRight = head.calRight;
        TreeNode l = head.left;
        TreeNode r = head.right;
        CalNode leftNode = (CalNode)l;
        CalNode rightNode = (CalNode)r;
        if(calLeft+1 == k)
            return head;
        else if(k <= calLeft)
            return searchNoK(leftNode, k);
        else
            return searchNoK(rightNode, k-calLeft-1);
    }

    CalNode afterOrder(TreeNode head){
        if(head == null) return null;
        CalNode res = new CalNode(head.val);

        res.left = afterOrder(head.left);
        res.right = afterOrder(head.right);
        if(res.left!=null){
            CalNode l = (CalNode)(res.left);
            res.calLeft = l.calLeft + l.calRight+1;
        }

        if(res.right!=null){
            CalNode r = (CalNode)(res.right);
            res.calRight = r.calLeft + r.calRight+1;
        }
        return res;
    }

}
class CalNode extends TreeNode{
    public int calLeft = 0;
    public int calRight = 0;
    public CalNode(int val){
        super(val);
    }
}
```



