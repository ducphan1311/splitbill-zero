import xml.etree.ElementTree as ET

def create_splitbill_diagram():
    mxfile = ET.Element('mxfile', {
        'host': 'app.diagrams.net',
        'modified': '2026-10-28T09:00:00.000Z',
        'agent': 'OpenClaw System Architect',
        'version': '24.7.5',
        'type': 'device'
    })
    
    diagram = ET.SubElement(mxfile, 'diagram', {
        'id': 'splitbill-zero-architecture',
        'name': 'SplitBill Zero Architecture & Flow'
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
    
    # Theme Styles
    base_style = "rounded=1;whiteSpace=wrap;html=1;arcSize=10;fontFamily=Segoe UI,Helvetica,Arial;fontSize=12;strokeWidth=2;"
    title_style = "text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;fontFamily=Segoe UI,Helvetica,Arial;fontSize=24;fontStyle=1;fontColor=#0F172A;"
    subtitle_style = "text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;fontFamily=Segoe UI,Helvetica,Arial;fontSize=13;fontColor=#64748B;"
    container_style = "rounded=1;whiteSpace=wrap;html=1;arcSize=8;strokeWidth=1;dashed=1;fontFamily=Segoe UI,Helvetica,Arial;fontSize=14;fontStyle=1;verticalAlign=top;align=left;spacingLeft=15;spacingTop=10;"
    
    # 0. Title & Subtitle Header
    title = ET.SubElement(root, 'mxCell', {
        'id': 'header_title',
        'value': '⚡ SplitBill Zero — System Architecture & Real-Time Collaborative Flow',
        'style': title_style,
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(title, 'mxGeometry', {'x': '40', 'y': '25', 'width': '1000', 'height': '40', 'as': 'geometry'})
    
    subtitle = ET.SubElement(root, 'mxCell', {
        'id': 'header_sub',
        'value': 'Production-grade zero-install architecture: Edge OCR (Flutter/ML Kit) ➔ Real-Time Mesh Sync ➔ Lightweight Guest Web Client ➔ Dynamic VietQR (EMVCo) Settlement',
        'style': subtitle_style,
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(subtitle, 'mxGeometry', {'x': '40', 'y': '65', 'width': '1200', 'height': '25', 'as': 'geometry'})
    
    # Containers (Columns)
    c1 = ET.SubElement(root, 'mxCell', {
        'id': 'container_host',
        'value': '1. HOST MOBILE ENGINE (Native/Flutter App)',
        'style': container_style + "fillColor=#F8FAFC;strokeColor=#0284C7;fontColor=#0369A1;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(c1, 'mxGeometry', {'x': '40', 'y': '110', 'width': '380', 'height': '680', 'as': 'geometry'})
    
    c2 = ET.SubElement(root, 'mxCell', {
        'id': 'container_realtime',
        'value': '2. REAL-TIME SESSION ENGINE (Cloud / Edge Mesh)',
        'style': container_style + "fillColor=#F8FAFC;strokeColor=#6366F1;fontColor=#4338CA;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(c2, 'mxGeometry', {'x': '460', 'y': '110', 'width': '380', 'height': '680', 'as': 'geometry'})

    c3 = ET.SubElement(root, 'mxCell', {
        'id': 'container_guest',
        'value': '3. ZERO-INSTALL GUEST CLIENT (Mobile Web)',
        'style': container_style + "fillColor=#F8FAFC;strokeColor=#10B981;fontColor=#047857;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(c3, 'mxGeometry', {'x': '880', 'y': '110', 'width': '380', 'height': '680', 'as': 'geometry'})

    c4 = ET.SubElement(root, 'mxCell', {
        'id': 'container_fintech',
        'value': '4. FINTECH SETTLEMENT (VietQR / Napas 247)',
        'style': container_style + "fillColor=#F8FAFC;strokeColor=#F59E0B;fontColor=#B45309;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(c4, 'mxGeometry', {'x': '1300', 'y': '110', 'width': '380', 'height': '680', 'as': 'geometry'})

    # Nodes Column 1: Host Mobile Engine
    n_cam = ET.SubElement(root, 'mxCell', {
        'id': 'n_cam',
        'value': '<b>Camera Stream Layer</b><br/><font color="#64748B">CameraX (Android) / AVFoundation (iOS)<br/>30fps YUV420 Image Analysis Buffer</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#0284C7;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_cam, 'mxGeometry', {'x': '65', 'y': '160', 'width': '330', 'height': '75', 'as': 'geometry'})

    n_ml = ET.SubElement(root, 'mxCell', {
        'id': 'n_ml',
        'value': '<b>Google ML Kit Text Recognition v2</b><br/><font color="#64748B">On-Device Edge OCR (Vietnamese Latin script)<br/>Latency &lt; 50ms, Zero Cloud Cost</font>',
        'style': base_style + "fillColor=#E0F2FE;strokeColor=#0284C7;fontColor=#0369A1;fontStyle=1;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_ml, 'mxGeometry', {'x': '65', 'y': '270', 'width': '330', 'height': '80', 'as': 'geometry'})

    n_parser = ET.SubElement(root, 'mxCell', {
        'id': 'n_parser',
        'value': '<b>Bill Parser & Line RegEx Matcher</b><br/><font color="#64748B">Spatial Bounding Box Clustering<br/>Item Name + Price (VND) Normalizer<br/>Tax & Surcharge Distributer</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#0284C7;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_parser, 'mxGeometry', {'x': '65', 'y': '385', 'width': '330', 'height': '90', 'as': 'geometry'})

    n_room_init = ET.SubElement(root, 'mxCell', {
        'id': 'n_room_init',
        'value': '<b>Room Session Dispatcher</b><br/><font color="#64748B">Generate 6-character Short Code & URL<br/>Render Table Joining QR for Guests</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#0284C7;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_room_init, 'mxGeometry', {'x': '65', 'y': '510', 'width': '330', 'height': '75', 'as': 'geometry'})

    n_host_dash = ET.SubElement(root, 'mxCell', {
        'id': 'n_host_dash',
        'value': '<b>Host Live Dashboard</b><br/><font color="#64748B">Real-time Guest Tracker & Settlement Status<br/>Sync Paid/Unpaid Badges via WebSocket</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#0284C7;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_host_dash, 'mxGeometry', {'x': '65', 'y': '620', 'width': '330', 'height': '75', 'as': 'geometry'})

    # Nodes Column 2: Realtime Session Engine
    n_rt_gateway = ET.SubElement(root, 'mxCell', {
        'id': 'n_rt_gateway',
        'value': '<b>Real-Time Room Gateway</b><br/><font color="#64748B">Supabase Realtime / WebSocket Mesh<br/>Topic: `room:${roomId}` Presence & Broadcast</font>',
        'style': base_style + "fillColor=#EEF2FF;strokeColor=#6366F1;fontColor=#3730A3;fontStyle=1;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_rt_gateway, 'mxGeometry', {'x': '485', 'y': '160', 'width': '330', 'height': '80', 'as': 'geometry'})

    n_state_store = ET.SubElement(root, 'mxCell', {
        'id': 'n_state_store',
        'value': '<b>Ephemeral State Store (In-Memory / Redis)</b><br/><font color="#64748B">`items`: [{id, name, price, shares: []}]<br/>`guests`: [{id, name, totalAmount, status}]<br/>TTL: 2 Hours auto-expiry (Privacy-first)</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#6366F1;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_state_store, 'mxGeometry', {'x': '485', 'y': '280', 'width': '330', 'height': '95', 'as': 'geometry'})

    n_split_algo = ET.SubElement(root, 'mxCell', {
        'id': 'n_split_algo',
        'value': '<b>Fair Split Calculation Engine</b><br/><font color="#64748B">Direct Item Assignment: $Cost = Price$<br/>Shared Dishes: $Cost = Price / N_{guests}$<br/>Proportional Tax/Tips Allocation Matrix</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#6366F1;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_split_algo, 'mxGeometry', {'x': '485', 'y': '415', 'width': '330', 'height': '90', 'as': 'geometry'})

    n_webhook = ET.SubElement(root, 'mxCell', {
        'id': 'n_webhook',
        'value': '<b>Payment Event Webhook Listener</b><br/><font color="#64748B">Casso / Open Banking Webhook Listener<br/>Matches Transfer Note ➔ Emits `PAID` event</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#6366F1;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_webhook, 'mxGeometry', {'x': '485', 'y': '545', 'width': '330', 'height': '80', 'as': 'geometry'})

    # Nodes Column 3: Zero-Install Guest Web Client
    n_qr_scan = ET.SubElement(root, 'mxCell', {
        'id': 'n_qr_scan',
        'value': '<b>Guest Joins Table via Native QR Scan</b><br/><font color="#64748B">iPhone Camera / Android Lens / Zalo QR<br/>Direct deep-link to Web: `bill.io/r/XYZ123`</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#10B981;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_qr_scan, 'mxGeometry', {'x': '905', 'y': '160', 'width': '330', 'height': '75', 'as': 'geometry'})

    n_pwa = ET.SubElement(root, 'mxCell', {
        'id': 'n_pwa',
        'value': '<b>Ultra-Lightweight Mobile Web Client</b><br/><font color="#64748B">Zero App Download | Zero Login Barrier<br/>React / Svelte / Flutter Web (Bundle &lt; 250KB)<br/>Instant input: Enter Name &amp; Start Picking</font>',
        'style': base_style + "fillColor=#ECFDF5;strokeColor=#10B981;fontColor=#065F46;fontStyle=1;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_pwa, 'mxGeometry', {'x': '905', 'y': '270', 'width': '330', 'height': '85', 'as': 'geometry'})

    n_item_picker = ET.SubElement(root, 'mxCell', {
        'id': 'n_item_picker',
        'value': '<b>Real-Time Interactive Dish Board</b><br/><font color="#64748B">Tap to claim item | Multiple select for shared<br/>Live avatars showing who picked what<br/>Optimistic UI updates + Haptic feedback</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#10B981;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_item_picker, 'mxGeometry', {'x': '905', 'y': '395', 'width': '330', 'height': '85', 'as': 'geometry'})

    n_guest_pay = ET.SubElement(root, 'mxCell', {
        'id': 'n_guest_pay',
        'value': '<b>Guest Breakdown &amp; Pay Action</b><br/><font color="#64748B">1-Click "Pay via Bank App" (Deep Link)<br/>Displays Personalized Dynamic VietQR</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#10B981;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_guest_pay, 'mxGeometry', {'x': '905', 'y': '520', 'width': '330', 'height': '75', 'as': 'geometry'})

    # Nodes Column 4: Fintech Settlement
    n_emvco = ET.SubElement(root, 'mxCell', {
        'id': 'n_emvco',
        'value': '<b>EMVCo / VietQR Specification Encoder</b><br/><font color="#64748B">Tag 00: Payload Format Indicator (01)<br/>Tag 26: NAPAS Merchant Identifier (BNK ID + ACC)<br/>Tag 53: Transaction Currency (704 = VND)<br/>Tag 54: Precise Exact Amount (e.g. 84,500)<br/>Tag 62: Additional Data (Bill ID + Guest Name)</font>',
        'style': base_style + "fillColor=#FEF3C7;strokeColor=#F59E0B;fontColor=#78350F;fontStyle=1;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_emvco, 'mxGeometry', {'x': '1325', 'y': '160', 'width': '330', 'height': '135', 'as': 'geometry'})

    n_crc16 = ET.SubElement(root, 'mxCell', {
        'id': 'n_crc16',
        'value': '<b>CRC-16 / CCITT-FALSE Verification</b><br/><font color="#64748B">Polynomial 0x1021 Checksum Generation<br/>Ensures 100% Banking App Scanning Accuracy</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#F59E0B;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_crc16, 'mxGeometry', {'x': '1325', 'y': '330', 'width': '330', 'height': '75', 'as': 'geometry'})

    n_bank_app = ET.SubElement(root, 'mxCell', {
        'id': 'n_bank_app',
        'value': '<b>Guest Banking Apps (40+ VN Banks)</b><br/><font color="#64748B">Vietcombank, Techcombank, VPBank, MBBank...<br/>Auto-populates: Recipient, Amount, Transfer Note</font>',
        'style': base_style + "fillColor=#FFFFFF;strokeColor=#F59E0B;fontColor=#0F172A;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_bank_app, 'mxGeometry', {'x': '1325', 'y': '440', 'width': '330', 'height': '75', 'as': 'geometry'})

    n_settle_confirm = ET.SubElement(root, 'mxCell', {
        'id': 'n_settle_confirm',
        'value': '<b>Instant Settlement &amp; Auto-Reconcile</b><br/><font color="#64748B">Money landed on Host Bank Account<br/>Web &amp; App UI instant green checkmark</font>',
        'style': base_style + "fillColor=#D1FAE5;strokeColor=#059669;fontColor=#065F46;fontStyle=1;",
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(n_settle_confirm, 'mxGeometry', {'x': '1325', 'y': '550', 'width': '330', 'height': '75', 'as': 'geometry'})

    # Connectors & Edges
    edge_style = "edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;"

    def add_edge(id, s_id, t_id, label="", color="#64748B", dashed="0"):
        style = f"{edge_style}strokeColor={color};fontColor={color};dashed={dashed};"
        e = ET.SubElement(root, 'mxCell', {
            'id': id,
            'value': label,
            'style': style,
            'parent': '1',
            'source': s_id,
            'target': t_id,
            'edge': '1'
        })
        ET.SubElement(e, 'mxGeometry', {'relative': '1', 'as': 'geometry'})

    add_edge('e1', 'n_cam', 'n_ml', 'Image Frames (YUV)', '#0284C7')
    add_edge('e2', 'n_ml', 'n_parser', 'Text Blocks + Boxes', '#0284C7')
    add_edge('e3', 'n_parser', 'n_room_init', 'Parsed Receipt JSON', '#0284C7')
    add_edge('e4', 'n_room_init', 'n_rt_gateway', 'POST Create Room (Items + Host Info)', '#6366F1')
    add_edge('e5', 'n_rt_gateway', 'n_state_store', 'Cache Session', '#6366F1')
    add_edge('e6', 'n_room_init', 'n_qr_scan', 'Display Join QR on Host Screen', '#10B981', dashed="1")
    add_edge('e7', 'n_qr_scan', 'n_pwa', 'Open Browser Session', '#10B981')
    add_edge('e8', 'n_pwa', 'n_item_picker', 'Guest Profile Created', '#10B981')
    add_edge('e9', 'n_item_picker', 'n_rt_gateway', 'WebSocket: `select_item` / `unselect`', '#6366F1')
    add_edge('e10', 'n_rt_gateway', 'n_split_algo', 'Recalculate Split', '#6366F1')
    add_edge('e11', 'n_split_algo', 'n_host_dash', 'Broadcast Updated Table State', '#0284C7')
    add_edge('e12', 'n_item_picker', 'n_guest_pay', 'Guest Clicks "Confirm & Pay"', '#10B981')
    add_edge('e13', 'n_guest_pay', 'n_emvco', 'Amount + Host Acc + Ref Note', '#F59E0B')
    add_edge('e14', 'n_emvco', 'n_crc16', 'Raw Payload String', '#F59E0B')
    add_edge('e15', 'n_crc16', 'n_bank_app', 'Render Dynamic VietQR', '#F59E0B')
    add_edge('e16', 'n_bank_app', 'n_settle_confirm', 'Napas 247 Instant Transfer', '#059669')
    add_edge('e17', 'n_settle_confirm', 'n_webhook', 'Notification Webhook', '#059669', dashed="1")
    add_edge('e18', 'n_webhook', 'n_host_dash', 'Broadcast `PAID` State', '#059669')

    tree = ET.ElementTree(mxfile)
    tree.write('projects/splitbill-zero/docs/SplitBill_Zero_Architecture.drawio', encoding='utf-8', xml_declaration=True)
    print("Exported drawio file successfully!")

if __name__ == '__main__':
    create_splitbill_diagram()
