import graphviz

dot = graphviz.Digraph('RC_State_Machine', format='svg')
dot.attr(rankdir='TB', splines='polyline', fontname='Helvetica', nodesep='0.6', ranksep='0.8', pad='0.3')

dot.node_attr.update(shape='box', style='rounded,filled', fontname='Helvetica', fontsize='13', margin='0.3,0.2')
dot.edge_attr.update(fontname='Helvetica', fontsize='11', color='#475569', fontcolor='#1e293b', penwidth='1.5')

# Nodes
dot.node('Buf', 'Virtual Buffer\n(虚拟蓄水池)', fillcolor='#bae6fd', color='#0284c7', penwidth='2')
dot.node('Before', 'BeforePicRc\n(帧级预算分配)', fillcolor='#fed7aa', color='#ea580c', penwidth='2')
dot.node('Quant', 'PicQuant\n(初始 QP 推演)', fillcolor='#fef08a', color='#ca8a04', penwidth='2')

with dot.subgraph(name='cluster_hw') as hw:
    hw.attr(style='dashed,rounded', color='#f472b6', bgcolor='#fdf2f8', label='Hardware Execution (硬件控制区)', fontcolor='#be185d', fontname='Helvetica-Bold', margin='20')
    hw.node('HW', 'HW Encode\n(AQ自适应 CU 级 Delta QP 微调)', fillcolor='#fbcfe8', color='#db2777', shape='component', penwidth='2')
    hw.node('Actual', 'Actual BitCnt\n(物理真实消耗)', fillcolor='#e9d5ff', color='#9333ea', penwidth='2')
    hw.edge('HW', 'Actual', label=' 输出物理码流 ')

dot.node('After', 'AfterPicRc\n(反馈对账与模型校准)', fillcolor='#bbf7d0', color='#16a34a', penwidth='2')

# Forward edges
dot.edge('Buf', 'Before', label=' 提供剩余水位 ')
dot.edge('Before', 'Quant', label=' 下达预算\n(targetPicSize) ')
dot.edge('Quant', 'HW', label=' 下发基准与边界约束\n(qpHdr, qpMin, qpMax) ')
dot.edge('Actual', 'After', label=' 汇报执行结果\n(actualBitCnt) ')

# Feedback edges
dot.edge('After', 'Buf', label=' 真实扣账水位更新 ', style='dashed', constraint='false', color='#ef4444', fontcolor='#ef4444')
dot.edge('After', 'Quant', label=' 修正 R-Q 线性模型斜率\n(linReg.weight) ', style='dashed', constraint='false', color='#ef4444', fontcolor='#ef4444')

dot.render('html/rc_arch_flow', cleanup=True)
print("SVG generated successfully.")
