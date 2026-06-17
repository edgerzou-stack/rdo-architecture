import graphviz
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

def draw_arch_flow():
    dot = graphviz.Digraph(comment='RC Arch Flow', format='svg', engine='dot')
    dot.attr(rankdir='LR', splines='spline', nodesep='0.6', ranksep='0.8', pad='0.2', fontname='Helvetica, Arial, sans-serif')
    
    with dot.subgraph(name='cluster_Macro') as c:
        c.attr(label='码率控制双向闭环 (Rate Control Closed Loop)', style='filled, rounded', fillcolor='#f8fafc', color='#cbd5e1', penwidth='2', fontname='Helvetica, Arial, sans-serif', fontsize='22', margin='12')
        
        c.attr('node', shape='box', style='filled, rounded', fontname='Helvetica, Arial, sans-serif', fontsize='18', margin='0.2,0.1')
        c.attr('edge', fontname='Helvetica, Arial, sans-serif', fontsize='16', penwidth='1.8')
        
        # Nodes
        c.node('HRD', '虚拟蓄水池\n(Virtual Buffer)', fillcolor='#e1f5fe', color='#0288d1')
        c.node('Alloc', '帧级分配\n(BeforePicRc)', fillcolor='#fff3e0', color='#f57c00')
        c.node('QP', '初始QP推演\n(PicQuant)', fillcolor='#fff3e0', color='#f57c00')
        c.node('Encode', '硬件物理编码\n(HW Encode)', fillcolor='#fce4ec', color='#c2185b')
        c.node('Actual', '实际产生比特\n(Actual BitCnt)', fillcolor='#ede7f6', color='#7e57c2')
        c.node('Update', '线性模型更新\n(AfterPicRc)', fillcolor='#e8f5e9', color='#2e7d32')
        
        # Edges
        c.edge('HRD', 'Alloc', label=' 目标比特/缓冲状态 ', weight='10')
        c.edge('Alloc', 'QP', label=' 目标大小/复杂度 ', weight='10')
        c.edge('QP', 'Encode', label=' 指导编码 ', weight='10')
        c.edge('Encode', 'Actual', weight='10')
        c.edge('Actual', 'Update', label=' 误差校准 ', weight='10')
        
        # Feedback loops
        c.edge('Update', 'HRD', label=' 扣除水位 ', style='dashed', constraint='false', dir='back')
        c.edge('Update', 'QP', label=' 修正 R-Q 模型 ', style='dashed', constraint='false', dir='back')

    output_path = os.path.join(script_dir, 'rc_arch_flow')
    dot.render(output_path, cleanup=True)

def draw_bit_allocation():
    dot = graphviz.Digraph(comment='RC Bit Allocation', format='svg', engine='dot')
    dot.attr(rankdir='LR', splines='spline', nodesep='0.6', ranksep='0.8', pad='0.2', fontname='Helvetica, Arial, sans-serif')
    
    with dot.subgraph(name='cluster_Alloc') as c:
        c.attr(label='帧级目标比特分配 (Bit Allocation & Intra Stealing)', style='filled, rounded', fillcolor='#f8fafc', color='#cbd5e1', penwidth='2', fontname='Helvetica, Arial, sans-serif', fontsize='22', margin='12')
        
        c.attr('node', shape='box', style='filled, rounded', fontname='Helvetica, Arial, sans-serif', fontsize='18', margin='0.2,0.1')
        c.attr('edge', fontname='Helvetica, Arial, sans-serif', fontsize='16', penwidth='1.8')
        
        c.node('vb', '基础预算\n(vb->bitPerPic)', fillcolor='#e1f5fe', color='#0288d1')
        c.node('Intra', 'I帧偷取\n(- intraBits)', fillcolor='#fce4ec', color='#c2185b')
        c.node('Err', '历史误差补偿\n(+ tmp/rcWindow)', fillcolor='#ede7f6', color='#7e57c2')
        c.node('Sum', '目标尺寸\n(targetPicSize)', shape='oval', fillcolor='#e8f5e9', color='#2e7d32')
        c.node('Limit', '下限保护\n(MAX(96+..., target))', fillcolor='#fff3e0', color='#f57c00')
        
        c.edge('vb', 'Sum', weight='10')
        c.edge('Intra', 'Sum', style='dashed')
        c.edge('Err', 'Sum', style='dashed')
        c.edge('Sum', 'Limit', weight='10')

    output_path = os.path.join(script_dir, 'rc_bit_allocation')
    dot.render(output_path, cleanup=True)

def draw_linreg_update():
    dot = graphviz.Digraph(comment='RC LinReg Update', format='svg', engine='dot')
    dot.attr(rankdir='LR', splines='spline', nodesep='0.5', ranksep='0.6', pad='0.2', fontname='Helvetica, Arial, sans-serif')
    
    with dot.subgraph(name='cluster_Update') as c:
        c.attr(label='线性模型更新与容错 (LinReg Model Refresh)', style='filled, rounded', fillcolor='#f8fafc', color='#cbd5e1', penwidth='2', fontname='Helvetica, Arial, sans-serif', fontsize='22', margin='12')
        
        c.attr('node', shape='box', style='filled, rounded', fontname='Helvetica, Arial, sans-serif', fontsize='18', margin='0.2,0.1')
        c.attr('edge', fontname='Helvetica, Arial, sans-serif', fontsize='16', penwidth='1.8')
        
        c.node('HW', '编码结束\n获取实际 bitCnt', fillcolor='#e1f5fe', color='#0288d1')
        c.node('Scene', '场景切换检测\n(SceneChangeCheck)', fillcolor='#fff3e0', color='#f57c00')
        c.node('Clear', '清空历史模型\n(EWLmemset)', fillcolor='#fce4ec', color='#c2185b')
        c.node('ErrRec', '记录预测误差\n(update_rc_error)', fillcolor='#ede7f6', color='#7e57c2')
        c.node('ModelUp', '更新R-Q参数\n(update_model)', fillcolor='#e8f5e9', color='#2e7d32')
        
        c.edge('HW', 'Scene', weight='10')
        c.edge('Scene', 'Clear', label=' Yes ', color='#c2185b', fontcolor='#c2185b')
        c.edge('Clear', 'ErrRec')
        c.edge('Scene', 'ErrRec', label=' No ', weight='10')
        c.edge('ErrRec', 'ModelUp', weight='10')

    output_path = os.path.join(script_dir, 'rc_linreg_update')
    dot.render(output_path, cleanup=True)

if __name__ == '__main__':
    draw_arch_flow()
    draw_bit_allocation()
    draw_linreg_update()
    print("Rate control SVG diagrams generated successfully.")
