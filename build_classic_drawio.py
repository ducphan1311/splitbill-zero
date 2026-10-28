import xml.etree.ElementTree as ET

def build_classic_drawio_architecture():
    mxfile = ET.Element('mxfile', {
        'host': 'app.diagrams.net',
        'modified': '2026-10-28T10:00:00.000Z',
        'agent': 'OpenClaw System Architect',
        'version': '24.7.5',
        'type': 'device'
    })
    
    diagram = ET.SubElement(mxfile, 'diagram', {
        'id': 'splitbill-zero-architecture-drawio-style',
        'name': 'SplitBill Zero Architecture'
    })
    
    graph_model = ET.SubElement(diagram, 'mxGraphModel', {
        'dx': '1800',
        'dy': '1100',
        'grid': '1',
        'gridSize': '10',
        'guides': '1',
        'tooltips': '1',
        'connect': '1',
        'arrows': '1',
        'fold': '1',
        'page': '1',
        'pageScale': '1',
        'pageWidth': '1920',
        'pageHeight': '1080',
        'math': '0',
        'shadow': '0'
    })
    
    root = ET.SubElement(graph_model, 'root')
    ET.SubElement(root, 'mxCell', {'id': '0'})
    ET.SubElement(root, 'mxCell', {'id': '1', 'parent': '0'})
    
    # Classic Clean Draw.io / UML Styles
    font = "fontFamily=Helvetica,Arial,sans-serif;"
    
    # Header Title
    title = ET.SubElement(root, 'mxCell', {
        'id': 'title',
        'value': '<b>SplitBill Zero: System Architecture & Subsystem Interactions</b>',
        'style': f'text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;fontSize=18;fontColor=#000000;{font}',
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(title, 'mxGeometry', {'x': '40', 'y': '30', 'width': '800', 'height': '30', 'as': 'geometry'})
    
    subtitle = ET.SubElement(root, 'mxCell', {
        'id': 'subtitle',
        'value': 'Standard Architectural Decomposition: Client Layer | Ingestion & Edge AI | Collaborative Mesh | Financial Settlement',
        'style': f'text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;fontSize=12;fontColor=#555555;{font}',
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(subtitle, 'mxGeometry', {'x': '40', 'y': '60', 'width': '1000', 'height': '20', 'as': 'geometry'})

    # Subsystem Containers (Draw.io Classic Groups: White background, subtle gray outline)
    def add_subsystem(id, x, y, w, h, name):
        c = ET.SubElement(root, 'mxCell', {
            'id': id,
            'value': f'<b>{name}</b>',
            'style': f'swimlane;whiteSpace=wrap;html=1;startSize=26;fillColor=#f8f9fa;strokeColor=#d6d8db;fontColor=#333333;fontSize=12;align=center;horizontal=1;startSize=28;arcSize=4;rounded=1;strokeWidth=1;{font}',
            'parent': '1',
            'vertex': '1'
        })
        ET.SubElement(c, 'mxGeometry', {'x': str(x), 'y': str(y), 'width': str(w), 'height': str(h), 'as': 'geometry'})
        return c

    add_subsystem('sub_client', 40, 100, 390, 640, 'Client Interaction Subsystem')
    add_subsystem('sub_ocr', 460, 100, 420, 640, 'Edge Ingestion & OCR Subsystem')
    add_subsystem('sub_mesh', 910, 100, 420, 640, 'Collaborative Mesh Subsystem')
    add_subsystem('sub_fintech', 1360, 100, 440, 640, 'Fintech Settlement Subsystem')

    # Draw.io Classic Node: Clean White, solid subtle borders (#6c757d or #495057), clear typography
    def add_box(id, parent, x, y, w, h, title, desc, tag=""):
        val = f'<b>{title}</b>'
        if tag:
            val += f'<br/><font color="#666666" style="font-size:10px;">[{tag}]</font>'
        if desc:
            val += f'<hr style="margin:4px 0;border:0;border-top:1px solid #e9ecef;"/><font color="#495057" style="font-size:11px;">{desc}</font>'
        
        node = ET.SubElement(root, 'mxCell', {
            'id': id,
            'value': val,
            'style': f'rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#b1b7ba;strokeWidth=1.2;fontColor=#212529;fontSize=11;align=left;spacingLeft=8;spacingRight=8;arcSize=6;{font}',
            'parent': parent,
            'vertex': '1'
        })
        ET.SubElement(node, 'mxGeometry', {'x': str(x), 'y': str(y), 'width': str(w), 'height': str(h), 'as': 'geometry'})
        return node

    # Subsystem 1: Client
    add_box('c_host_app', 'sub_client', 25, 45, 340, 85, 'Host Application', 'Manages bill capture, table initialization, and verifies peer settlement status.', 'Flutter 3.x Native Engine')
    add_box('c_guest_pwa', 'sub_client', 25, 155, 340, 85, 'Guest Web Client', 'Ephemeral mobile web app. First load <800ms. Zero login or account requirements.', 'Svelte / PWA (<250KB)')
    add_box('c_dish_board', 'sub_client', 25, 265, 340, 85, 'Collaborative Dish Board', 'Interactive canvas displaying scanned line items with real-time peer selection tags.', 'Real-Time UI Component')
    add_box('c_deeplink', 'sub_client', 25, 375, 340, 85, 'Universal Bank Intent Router', 'Invokes registered banking app schemes on iOS/Android with pre-filled payment details.', 'Mobile OS Intent System')
    add_box('c_host_monitor', 'sub_client', 25, 485, 340, 85, 'Host Table Settlement Monitor', 'Live participant roster tracking paid vs. pending transfers with instant green checkmarks.', 'WebSocket Client Listener')

    # Subsystem 2: Edge OCR
    add_box('o_cam_pipeline', 'sub_ocr', 25, 45, 370, 85, 'Frame Extraction Pipeline', 'Captures 30fps YUV420 image buffers with hardware auto-focus and brightness normalization.', 'CameraX / AVFoundation')
    add_box('o_mlkit', 'sub_ocr', 25, 155, 370, 85, 'On-Device Text Recognition', 'Neural Latin/Vietnamese text recognition engine running offline on device NPU/CPU.', 'Google ML Kit Text v2')
    add_box('o_clustering', 'sub_ocr', 25, 265, 370, 85, 'Spatial 2D Geometric Clustering', 'Groups fragmented text blocks by vertical proximity and correlates item names with right-aligned numeric VND values.', 'Spatial Heuristics')
    add_box('o_tax_parser', 'sub_ocr', 25, 375, 370, 85, 'Receipt Normalizer & Tax Allocator', 'Extracts and parses subtotal, VAT (8-10%), and service charges into structured BillItem entities.', 'Normalization Engine')
    add_box('o_integrity_check', 'sub_ocr', 25, 485, 370, 85, 'Sum Discrepancy Validator', 'Validates sum of parsed items against receipt grand total. Flags discrepancies for host confirmation.', 'Integrity Checker')

    # Subsystem 3: Mesh
    add_box('m_ws_gateway', 'sub_mesh', 25, 45, 370, 85, 'WebSocket Realtime Gateway', 'Low-latency bidirectional Pub/Sub message broker routing room state on topic `room:{roomId}`.', 'Supabase / Edge WS')
    add_box('m_state_cache', 'sub_mesh', 25, 155, 370, 85, 'In-Memory Session Store', 'Transient cache holding table state, line items, and guest claims. Configured with 2-hour TTL.', 'Redis / Ephemeral KV')
    add_box('m_split_calc', 'sub_mesh', 25, 265, 370, 85, 'Fair-Split Mathematical Matrix', 'Deterministic split engine: Individual Cost = Private + (Shared / N_guests) + Proportional VAT.', 'Financial Calculation Core')
    add_box('m_presence', 'sub_mesh', 25, 375, 370, 85, 'Peer Presence & Heartbeat Daemon', 'Monitors connection health, detects disconnects, and broadcasts real-time participant status.', 'Presence Tracker')
    add_box('m_reconciler', 'sub_mesh', 25, 485, 370, 85, 'Payment Reconciliation Consumer', 'Consumes incoming settlement notifications and pushes `PAID` events to table participants.', 'Event Consumer')

    # Subsystem 4: Fintech
    add_box('f_emvco', 'sub_fintech', 25, 45, 390, 85, 'EMVCo Tag Synthesizer', 'Encodes NAPAS 247 payload: Tag 00 (Format), Tag 26 (Bank BIN + Acc), Tag 53 (704 VND), Tag 54 (Amount).', 'EMVCo / VietQR Standard')
    add_box('f_crc16', 'sub_fintech', 25, 155, 390, 85, 'CRC-16 / CCITT-FALSE Engine', 'Calculates standard 16-bit redundancy polynomial 0x1021 ensuring 100% banking scanner compatibility.', 'Cyclic Redundancy Check')
    add_box('f_matrix_gen', 'sub_fintech', 25, 265, 390, 85, 'Dynamic QR Matrix Generator', 'Generates crisp vector ISO/IEC 18004 QR codes containing individualized payment data.', 'ISO 18004 Standard')
    add_box('f_bank_apps', 'sub_fintech', 25, 375, 390, 85, 'Guest Banking Applications', '40+ NAPAS member banking apps (Vietcombank, Techcombank, VPBank, MBBank, Cake, Timo, etc.).', 'Banking Ecosystem')
    add_box('f_napas_mesh', 'sub_fintech', 25, 485, 390, 85, 'Napas 24/7 Interbank Network', 'Facilitates instant real-time bank settlement directly into Host bank account.', 'Real-Time Clearing')

    # Connectors: Draw.io Classic Style (Solid gray/dark arrows, clean labels)
    edge_style = "edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=1.2;strokeColor=#495057;fontColor=#212529;fontSize=10;"
    
    def connect(id, s, t, label="", dashed="0", color="#495057"):
        st = f"{edge_style}dashed={dashed};strokeColor={color};{font}"
        e = ET.SubElement(root, 'mxCell', {
            'id': id,
            'value': label,
            'style': st,
            'parent': '1',
            'source': s,
            'target': t,
            'edge': '1'
        })
        ET.SubElement(e, 'mxGeometry', {'relative': '1', 'as': 'geometry'})

    connect('e1', 'c_host_app', 'o_cam_pipeline', 'Image Frame Stream')
    connect('e2', 'o_cam_pipeline', 'o_mlkit', 'YUV Buffer')
    connect('e3', 'o_mlkit', 'o_clustering', 'Text Blocks')
    connect('e4', 'o_clustering', 'o_tax_parser', 'Paired Items')
    connect('e5', 'o_tax_parser', 'o_integrity_check', 'Bill Entities')
    connect('e6', 'o_integrity_check', 'c_host_app', 'Verified Receipt JSON')
    connect('e7', 'c_host_app', 'm_ws_gateway', 'POST Create Room')
    connect('e8', 'm_ws_gateway', 'm_state_cache', 'Persist Session')
    connect('e9', 'c_host_app', 'c_guest_pwa', 'Scan Table Join QR', dashed="1")
    connect('e10', 'c_guest_pwa', 'c_dish_board', 'Load Canvas')
    connect('e11', 'c_dish_board', 'm_ws_gateway', 'WS: `claim_dish`')
    connect('e12', 'm_ws_gateway', 'm_split_calc', 'Calculate Split')
    connect('e13', 'm_split_calc', 'm_state_cache', 'Update Snapshot')
    connect('e14', 'm_state_cache', 'c_dish_board', 'Broadcast Snapshot')
    connect('e15', 'c_dish_board', 'f_emvco', 'Request Dynamic QR')
    connect('e16', 'f_emvco', 'f_crc16', 'Raw TLV String')
    connect('e17', 'f_crc16', 'f_matrix_gen', 'Checksummed String')
    connect('e18', 'f_matrix_gen', 'c_deeplink', 'Render QR & Deep Link')
    connect('e19', 'c_deeplink', 'f_bank_apps', 'Open App with Payment Data')
    connect('e20', 'f_bank_apps', 'f_napas_mesh', 'Authorize Transfer')
    connect('e21', 'f_napas_mesh', 'm_reconciler', 'Transfer Confirmation', dashed="1")
    connect('e22', 'm_reconciler', 'c_host_monitor', 'Push `PAID` State')

    tree = ET.ElementTree(mxfile)
    tree.write('projects/splitbill-zero/docs/SplitBill_Zero_Architecture.drawio', encoding='utf-8', xml_declaration=True)
    print("Built classic Draw.io architecture file successfully!")

if __name__ == '__main__':
    build_classic_drawio_architecture()
