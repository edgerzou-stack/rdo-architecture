import graphviz
import os

out_dir = os.path.dirname(os.path.abspath(__file__))

def draw_mpm_tree():
    dot = graphviz.Digraph(format='svg', name='mpm_tree')
    dot.attr(rankdir='TD', bgcolor='transparent')
    dot.attr('node', shape='box', style='rounded,filled', fontname='sans-serif')
    dot.attr('edge', fontname='sans-serif', fontsize='10')

    dot.node('Start', '获取左侧模式 A 和上方模式 B\n注：不可用或非 Intra 置为 DC', fillcolor='#f8fafc', color='#cbd5e1')
    dot.node('CondEqual', 'A == B ?', shape='diamond', fillcolor='#fdf4ff', color='#d946ef')
    
    dot.node('CondAngular', 'A 是角度模式?\n(Mode > 1)', shape='diamond', fillcolor='#fdf4ff', color='#d946ef')
    dot.node('MpmAng', 'MPM = [ A, 逆时针(A-1), 顺时针(A+1) ]', fillcolor='#f0fdf4', color='#22c55e', fontname='sans-serif bold')
    dot.node('MpmNonAng', 'MPM = [ Planar(0), DC(1), 垂直(26) ]', fillcolor='#f0fdf4', color='#22c55e', fontname='sans-serif bold')
    
    dot.node('BaseMpm', 'MPM[0] = A\nMPM[1] = B', fillcolor='#f8fafc', color='#cbd5e1')
    dot.node('CondPlanar', 'A 和 B 都\n不是 Planar(0) ?', shape='diamond', fillcolor='#fdf4ff', color='#d946ef')
    
    dot.node('MpmP', 'MPM[2] = Planar(0)', fillcolor='#f0fdf4', color='#22c55e', fontname='sans-serif bold')
    dot.node('CondDC', '另一个是否\n为 DC(1) ?', shape='diamond', fillcolor='#fdf4ff', color='#d946ef')
    
    dot.node('MpmV', 'MPM[2] = 垂直(26)', fillcolor='#f0fdf4', color='#22c55e', fontname='sans-serif bold')
    dot.node('MpmD', 'MPM[2] = DC(1)', fillcolor='#f0fdf4', color='#22c55e', fontname='sans-serif bold')

    dot.edge('Start', 'CondEqual')
    dot.edge('CondEqual', 'CondAngular', label='是 (A == B)')
    dot.edge('CondAngular', 'MpmAng', label='是')
    dot.edge('CondAngular', 'MpmNonAng', label='否 (Planar 或 DC)')
    
    dot.edge('CondEqual', 'BaseMpm', label='否 (A != B)')
    dot.edge('BaseMpm', 'CondPlanar')
    dot.edge('CondPlanar', 'MpmP', label='是 (都不含 0)')
    dot.edge('CondPlanar', 'CondDC', label='否 (必然含 0)')
    dot.edge('CondDC', 'MpmV', label='是 (即含 0 和 1)')
    dot.edge('CondDC', 'MpmD', label='否 (即含 0 和 角度)')

    dot.render(os.path.join(out_dir, 'mpm_tree'), cleanup=True)

def draw_intra_flow():
    dot = graphviz.Digraph(format='svg', name='intra_flow')
    dot.attr(rankdir='LR', bgcolor='transparent')
    dot.attr('node', shape='box', style='rounded,filled', fontname='sans-serif')
    dot.attr('edge', fontname='sans-serif', fontsize='10')

    dot.node('A', '当前块 Intra 模式', fillcolor='white')
    dot.node('B', '是否在 MPM 列表中?', shape='diamond', fillcolor='#fdf4ff', color='#d946ef')
    dot.node('C', '传输 mpm_idx', fillcolor='white')
    dot.node('D', '截断一元码\n[纯 Bypass 引擎]', fillcolor='#f8fafc', color='#64748b', shape='ellipse')
    dot.node('E', '传输 rem_mode', fillcolor='white')
    dot.node('F', '固定 5-bit\n[纯 Bypass 引擎]', fillcolor='#f8fafc', color='#64748b', shape='ellipse')

    dot.edge('A', 'B')
    dot.edge('B', 'C', label='是 (flag = 1)\n[CABAC 查表]')
    dot.edge('C', 'D')
    dot.edge('B', 'E', label='否 (flag = 0)\n[CABAC 查表]')
    dot.edge('E', 'F')

    dot.render(os.path.join(out_dir, 'intra_flow'), cleanup=True)

def draw_inter_mode_tree():
    dot = graphviz.Digraph(format='svg', name='inter_mode_tree')
    dot.attr(rankdir='TD', bgcolor='transparent')
    dot.attr('node', shape='box', style='rounded,filled', fillcolor='#f1f5f9', fontname='sans-serif')
    dot.attr('edge', fontname='sans-serif', fontsize='10')

    dot.node('Start', '进入 Inter 预测块', fillcolor='#dbeafe')
    dot.node('SkipFlag', 'cu_skip_flag ?\n(是否启用 Skip)', shape='diamond', fillcolor='#fef3c7')
    dot.node('SkipMergeIdx', '发 merge_idx\n(选择哪个邻居)')
    dot.node('SkipEnd', '结束\n(无纹理残差)', shape='ellipse', fillcolor='#fce7f3')
    
    dot.node('MergeFlag', 'merge_flag ?\n(是否启用 Merge)', shape='diamond', fillcolor='#fef3c7')
    dot.node('MergeIdx', '发 merge_idx\n(选择哪个邻居)')
    dot.node('Residual', '发纹理残差\n(CBF 和 Coeff)')
    
    dot.node('InterDir', '发 inter_pred_idc\n(仅 B-Slice: 选 L0/L1/Bi)')
    dot.node('L0_L1_Loop', '对激活的参考方向 (L0或L1)')
    dot.node('RefIdx', '发 ref_idx\n(参考帧索引)')
    dot.node('MVD', '发 MVD\n(运动矢量差分)')

    dot.edge('Start', 'SkipFlag')
    dot.edge('SkipFlag', 'SkipMergeIdx', label='1 (Skip 模式)')
    dot.edge('SkipMergeIdx', 'SkipEnd')
    
    dot.edge('SkipFlag', 'MergeFlag', label='0 (常规 Inter)')
    dot.edge('MergeFlag', 'MergeIdx', label='1 (Merge 模式)')
    dot.edge('MergeIdx', 'Residual')
    
    dot.edge('MergeFlag', 'InterDir', label='0 (AMVP 模式)')
    dot.edge('InterDir', 'L0_L1_Loop')
    dot.edge('L0_L1_Loop', 'RefIdx')
    dot.edge('RefIdx', 'MVD')

    dot.render(os.path.join(out_dir, 'inter_mode_tree'), cleanup=True)

def draw_mvd_flow():
    dot = graphviz.Digraph(format='svg', name='mvd_flow')
    dot.attr(rankdir='TD', bgcolor='transparent')
    dot.attr('node', shape='box', style='rounded,filled', fillcolor='#f1f5f9', fontname='sans-serif')
    dot.attr('edge', fontname='sans-serif', fontsize='10')

    dot.node('MVD', '输入的 MVD 分量')
    dot.node('Q1', '|MVD| > 0 ?\n(零值检测)', shape='diamond', fillcolor='#fef3c7')
    dot.node('Q2', '|MVD| > 1 ?\n(大值检测)', shape='diamond', fillcolor='#fef3c7')
    dot.node('End', '提前结束', shape='ellipse', fillcolor='#dbeafe')
    dot.node('GR', '提取残差: L = |MVD| - 2')
    dot.node('Sign', '进入符号位处理')
    dot.node('Bypass', 'Golomb-Rice 编码 (Bypass 旁路)\n发送截断一元码', fillcolor='#e2e8f0')
    dot.node('SignEnc', '发送符号位 (Bypass 旁路)', fillcolor='#e2e8f0')

    dot.edge('MVD', 'Q1')
    dot.edge('Q1', 'Q2', label='是\n[CABAC Context 查表]')
    dot.edge('Q1', 'End', label='否\n[CABAC Context 查表]')
    
    dot.edge('Q2', 'GR', label='是\n[切换 Context 查表]')
    dot.edge('Q2', 'Sign', label='否\n[切换 Context 查表]')
    
    dot.edge('GR', 'Bypass')
    dot.edge('Bypass', 'Sign')
    dot.edge('Sign', 'SignEnc')

    dot.render(os.path.join(out_dir, 'mvd_flow'), cleanup=True)

def draw_dpb_arch():
    dot = graphviz.Digraph(format='svg', name='dpb_arch')
    dot.attr(rankdir='LR', bgcolor='transparent', compound='true')
    dot.attr('node', shape='box', style='rounded,filled', fontname='sans-serif')
    dot.attr('edge', fontname='sans-serif', fontsize='10')

    with dot.subgraph(name='cluster_L0') as c:
        c.attr(style='filled', fillcolor='#fef3c7', color='#d97706', label='List 0 (过去帧 DPB)')
        c.node('L0_0', 'ref_idx = 0\n(t-1 帧)', fillcolor='white')
        c.node('L0_1', 'ref_idx = 1\n(t-2 帧)', fillcolor='white')
        c.node('L0_2', 'ref_idx = 2\n(t-3 帧)', fillcolor='white')
    
    with dot.subgraph(name='cluster_L1') as c:
        c.attr(style='filled', fillcolor='#fce7f3', color='#db2777', label='List 1 (未来帧 DPB)')
        c.node('L1_0', 'ref_idx = 0\n(t+1 帧)', fillcolor='white')
        c.node('L1_1', 'ref_idx = 1\n(t+2 帧)', fillcolor='white')

    dot.node('Current', '当前预测块 (CU)', fillcolor='#dbeafe', color='#3b82f6', penwidth='2')

    dot.edge('Current', 'L0_1', label='inter_pred_idc = 0\n仅查 L0')
    dot.edge('Current', 'L0_0', label='inter_pred_idc = 2\n双向 (Bi) 查 L0 和 L1', style='dashed')
    dot.edge('Current', 'L1_0', label='双向', style='dashed')

    dot.render(os.path.join(out_dir, 'dpb_arch'), cleanup=True)

def draw_soc_ddr_arch():
    dot = graphviz.Digraph(format='svg', name='soc_ddr_arch')
    dot.attr(rankdir='LR', bgcolor='transparent', compound='true')
    dot.attr('node', shape='box', style='rounded,filled', fontname='sans-serif')
    dot.attr('edge', fontname='sans-serif', fontsize='10')

    with dot.subgraph(name='cluster_External') as c:
        c.attr(style='dashed', fillcolor='#f1f5f9', color='#94a3b8', label='外部存储 (片外 DDR / LPDDR)')
        c.node('DPB', '完整 DPB 缓存区\n(最高 15 帧, 动辄上百 MB)', fillcolor='#cbd5e1', color='#64748b')
        c.node('Ignored', '被算法强行抛弃的老帧\n(拒绝访问以保带宽)', fillcolor='#fee2e2', color='#ef4444', fontcolor='#b91c1c')
        c.edge('DPB', 'Ignored', style='dotted', dir='none')

    with dot.subgraph(name='cluster_SoC') as c:
        c.attr(style='solid', fillcolor='#f0fdf4', color='#22c55e', penwidth='2', label='视频编码芯片 (片内 ASIC/SoC)')
        c.node('DMA', 'DMA 引擎\n(突发读取 Burst Fetch)', fillcolor='#fef08a', color='#eab308')
        c.node('SRAM', '片内 SRAM\n参考像素缓存\n(例如 128x128 搜索窗)', fillcolor='#bbf7d0', color='#22c55e')
        c.node('MEMC', 'ME / MC 硬件核心\n(运动估计与补偿)', fillcolor='#bfdbfe', color='#3b82f6')
        
        c.edge('DMA', 'SRAM', label='片内高速总线')
        c.edge('SRAM', 'MEMC', label='低延迟供给')

    dot.edge('DPB', 'DMA', label='仅按需加载\n当前块搜索窗', penwidth='2')

    dot.render(os.path.join(out_dir, 'soc_ddr_arch'), cleanup=True)

if __name__ == '__main__':
    draw_mpm_tree()
    draw_intra_flow()
    draw_inter_mode_tree()
    draw_mvd_flow()
    draw_dpb_arch()
    draw_soc_ddr_arch()
    print("Successfully generated 6 SVG diagrams.")
