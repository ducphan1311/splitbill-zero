import xml.etree.ElementTree as ET

def build_enterprise_architecture():
    mxfile = ET.Element('mxfile', {
        'host': 'app.diagrams.net',
        'modified': '2026-10-28T09:30:00.000Z',
        'agent': 'OpenClaw Enterprise Architect',
        'version': '24.7.5',
        'type': 'device'
    })
    
    diagram = ET.SubElement(mxfile, 'diagram', {
        'id': 'splitbill-zero-enterprise-arch',
        'name': 'SplitBill Zero Enterprise System Architecture'
    })
    
    graph_model = ET.SubElement(diagram, 'mxGraphModel', {
        'dx': '2000',
        'dy': '1200',
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
    
    # Global Enterprise Styles
    font = "fontFamily=SF Pro Display,-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial;"
    
    # Layer Backgrounds (Swimlanes / Subsystems)
    def add_layer(id, x, y, w, h, title, subtitle, stroke, fill, text_color):
        layer = ET.SubElement(root, 'mxCell', {
            'id': id,
            'value': f'<b>{title}</b><br/><font style="font-size:11px;font-weight:normal;" color="{text_color}">{subtitle}</font>',
            'style': f'rounded=1;whiteSpace=wrap;html=1;arcSize=4;strokeWidth=1.5;dashed=1;strokeColor={stroke};fillColor={fill};fontColor={text_color};fontSize=13;align=left;verticalAlign=top;spacingLeft=18;spacingTop=12;{font}',
            'parent': '1',
            'vertex': '1'
        })
        ET.SubElement(layer, 'mxGeometry', {'x': str(x), 'y': str(y), 'width': str(w), 'height': str(h), 'as': 'geometry'})
        return layer

    # 4 Subsystem Columns
    add_layer('sub_client', 40, 100, 420, 680, 'SUBSYSTEM A: CLIENT INTERACTION LAYER', 'Flutter Native Engine (Host) & Zero-Install Guest Web Client', '#0284C7', '#F0F9FF', '#0369A1')
    add_layer('sub_edge', 490, 100, 430, 680, 'SUBSYSTEM B: ON-DEVICE INGESTION & OCR ENGINE', 'Edge AI Computer Vision & Spatial Bounding-Box Heuristics', '#4F46E5', '#EEF2FF', '#3730A3')
    add_layer('sub_mesh', 950, 100, 430, 680, 'SUBSYSTEM C: COLLABORATIVE SESSION MESH', 'Low-Latency PubSub, Ephemeral State Cache & Matrix Math', '#059669', '#ECFDF5', '#065F46')
    add_layer('sub_fintech', 1410, 100, 470, 680, 'SUBSYSTEM D: BANKING & SETTLEMENT GATEWAY', 'EMVCo VietQR Tag Synthesis, CRC-16 Checksum & Napas 247', '#D97706', '#FFFBEB', '#92400E')

    # Header Element
    header = ET.SubElement(root, 'mxCell', {
        'id': 'main_header',
        'value': '<b>SPLITBILL ZERO: ENTERPRISE TECHNICAL ARCHITECTURE & SUBSYSTEM SPECIFICATION</b><br/><font style="font-size:12px;font-weight:normal;" color="#64748B">Distributed Collaborative Financial Settlement Protocol | IEC/ISO 18004 &amp; EMVCo Standard Compliant</font>',
        'style': f'text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;fontColor=#0F172A;fontSize=18;{font}',
        'parent': '1',
        'vertex': '1'
    })
    ET.SubElement(header, 'mxGeometry', {'x': '40', 'y': '30', 'width': '1400', 'height': '45', 'as': 'geometry'})

    # Component Box Helper
    def add_component(id, x, y, w, h, title, desc, tag, fill='#FFFFFF', stroke='#94A3B8', header_color='#0F172A'):
        val = f'<table style="width:100%;border-collapse:collapse;"><tr><td style="text-align:left;font-weight:bold;font-size:12px;color:{header_color};">{title}</td><td style="text-align:right;"><span style="font-size:9px;background:{stroke};color:#ffffff;padding:2px 5px;border-radius:3px;font-weight:600;">{tag}</span></td></tr><tr><td colspan="2" style="font-size:10.5px;color:#64748B;padding-top:4px;line-height:1.35;">{desc}</td></tr></table>'
        cell = ET.SubElement(root, 'mxCell', {
            'id': id,
            'value': val,
            'style': f'rounded=1;whiteSpace=wrap;html=1;arcSize=6;strokeWidth=1.5;strokeColor={stroke};fillColor={fill};align=left;verticalAlign=middle;spacing=10;{font}',
            'parent': '1',
            'vertex': '1'
        })
        ET.SubElement(cell, 'mxGeometry', {'x': str(x), 'y': str(y), 'width': str(w), 'height': str(h), 'as': 'geometry'})
        return cell

    # Subsystem A: Client Interaction
    add_component('c_flutter_host', 65, 170, 370, 85, 'Host Application (Flutter 3.x)', 'Orchestrates camera sessions, room lifecycles, and final settlement confirmation on table master device.', 'MOBILE HOST', '#FFFFFF', '#0284C7', '#0369A1')
    add_component('c_guest_pwa', 65, 290, 370, 85, 'Guest Web Client (Svelte / PWA)', 'Zero-install ephemeral web client (<250KB bundle). Instantly loaded via QR scan with zero authentication friction.', 'MOBILE WEB', '#FFFFFF', '#0284C7', '#0369A1')
    add_component('c_state_view', 65, 410, 370, 85, 'Real-Time Table Board (Virtual Dish Canvas)', 'Bidirectional synchronization of selected items with live peer avatars, shared indicators, and total cost preview.', 'UI COMPONENT', '#FFFFFF', '#0284C7', '#0369A1')
    add_component('c_deeplink_mgr', 65, 530, 370, 85, 'Universal Bank Intent Dispatcher', 'Dispatches direct iOS/Android URL schemes into VCB Digibank, Techcombank, VPBank NEO, and MBBank.', 'DEEPLINK', '#FFFFFF', '#0284C7', '#0369A1')

    # Subsystem B: Ingestion & OCR
    add_component('c_camerax', 515, 170, 380, 85, 'Camera Pipeline (CameraX / AVFoundation)', 'High-speed 30fps YUV420 frame streaming with automatic exposure, focus lock, and perspective correction.', 'HARDWARE API', '#FFFFFF', '#4F46E5', '#3730A3')
    add_component('c_mlkit_v2', 515, 290, 380, 85, 'Google ML Kit Text Recognition v2', 'On-device Latin & Vietnamese script neural text extractor. Latency <45ms, zero cloud telemetry, 100% privacy.', 'EDGE AI', '#FFFFFF', '#4F46E5', '#3730A3')
    add_component('c_spatial_cluster', 515, 410, 380, 95, '2D Geometric Spatial Clustering Engine', 'Clusters TextBlocks by vertical band (|ΔY| ≤ 0.5 * LineHeight) and correlates dish names with right-aligned numeric VND values.', 'ALGORITHM', '#FFFFFF', '#4F46E5', '#3730A3')
    add_component('c_receipt_parser', 515, 540, 380, 85, 'Receipt Normalizer & Tax Allocator', 'Detects Subtotal, Service Charges, VAT (8-10%) tags and computes normalized BillItem entity collection.', 'BUSINESS LOGIC', '#FFFFFF', '#4F46E5', '#3730A3')

    # Subsystem C: Collaborative Mesh
    add_component('c_ws_gateway', 975, 170, 380, 85, 'WebSocket / Supabase Realtime Gateway', 'Low-latency pub/sub message broker routing ephemeral events under topic `room:${roomId}`.', 'WEBSOCKET', '#FFFFFF', '#059669', '#065F46')
    add_component('c_mem_cache', 975, 290, 380, 85, 'In-Memory Session Store (Redis / Edge KV)', 'Holds volatile room entities: Table metadata, Guest presence, Item claims. Configured with 2-hour TTL auto-eviction.', 'EPHEMERAL CACHE', '#FFFFFF', '#059669', '#065F46')
    add_component('c_math_matrix', 975, 410, 380, 95, 'Fair-Split Deterministic Math Matrix', 'Formula: Cost = Σ(Private) + Σ(Shared / N_claimants) + Proportional VAT. Guarantees zero round-off discrepancy down to 1 VND.', 'FINANCIAL MATH', '#FFFFFF', '#059669', '#065F46')
    add_component('c_presence_tracker', 975, 540, 380, 85, 'Guest Presence & Heartbeat Daemon', 'Monitors peer disconnections, socket reconnects, and maintains authoritative active participant list.', 'DISTRIBUTED STATE', '#FFFFFF', '#059669', '#065F46')

    # Subsystem D: Fintech & Settlement
    add_component('c_emvco_tlv', 1435, 170, 420, 95, 'EMVCo QR Tag Synthesizer (NAPAS 247)', 'Encodes standard Tag-Length-Value hierarchy: Tag 00 (Format), Tag 26 (Acquiring Bank BIN + Host Account), Tag 53 (704 VND), Tag 54 (Amount).', 'EMVCo STANDARDS', '#FFFFFF', '#D97706', '#92400E')
    add_component('c_crc16_engine', 1435, 295, 420, 85, 'CRC-16 / CCITT-FALSE Checksum Engine', 'Computes standard 16-bit redundancy polynomial 0x1021. Guarantees 100% scanning validity on all banking scanners.', 'CRYPTOGRAPHY', '#FFFFFF', '#D97706', '#92400E')
    add_component('c_vietqr_renderer', 1435, 410, 420, 85, 'Dynamic QR Matrix Generator (ISO 18004)', 'Vector-based QR matrix generator embedding custom Host branding logo and Napas 247 identity frame.', 'GRAPHICS ENGINE', '#FFFFFF', '#D97706', '#92400E')
    add_component('c_reconcile_wh', 1435, 530, 420, 85, 'Payment Reconciliation Webhook / Poll', 'Parses incoming bank transaction references against guest claim tokens and automatically emits `PAID` confirmation.', 'RECONCILIATION', '#FFFFFF', '#D97706', '#92400E')

    # Edges Helper
    edge_style = "edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=1.5;"
    def add_link(id, s, t, label, color='#64748B', dashed='0'):
        e = ET.SubElement(root, 'mxCell', {
            'id': id,
            'value': f'<font style="font-size:10px;background:#ffffff;padding:1px 4px;border:1px solid {color};border-radius:3px;">{label}</font>',
            'style': f'{edge_style}strokeColor={color};fontColor={color};dashed={dashed};{font}',
            'parent': '1',
            'source': s,
            'target': t,
            'edge': '1'
        })
        ET.SubElement(e, 'mxGeometry', {'relative': '1', 'as': 'geometry'})

    add_link('l1', 'c_flutter_host', 'c_camerax', '1. Stream Frames', '#0284C7')
    add_link('l2', 'c_camerax', 'c_mlkit_v2', '2. Buffer Ingestion', '#4F46E5')
    add_link('l3', 'c_mlkit_v2', 'c_spatial_cluster', '3. Raw TextBlocks', '#4F46E5')
    add_link('l4', 'c_spatial_cluster', 'c_receipt_parser', '4. Item-Price Tuples', '#4F46E5')
    add_link('l5', 'c_receipt_parser', 'c_flutter_host', '5. Verified Receipt JSON', '#0284C7')
    add_link('l6', 'c_flutter_host', 'c_ws_gateway', '6. Initialize Room (REST/WS)', '#059669')
    add_link('l7', 'c_ws_gateway', 'c_mem_cache', '7. Store Session State', '#059669')
    add_link('l8', 'c_flutter_host', 'c_guest_pwa', '8. Join Table via QR Scan', '#0284C7', dashed='1')
    add_link('l9', 'c_guest_pwa', 'c_state_view', '9. Render Dish Canvas', '#0284C7')
    add_link('l10', 'c_state_view', 'c_ws_gateway', '10. Dispatch `claim_item`', '#059669')
    add_link('l11', 'c_ws_gateway', 'c_math_matrix', '11. Compute Settlement', '#059669')
    add_link('l12', 'c_math_matrix', 'c_mem_cache', '12. Update Room Snapshot', '#059669')
    add_link('l13', 'c_mem_cache', 'c_state_view', '13. Push State Broadcast', '#059669')
    add_link('l14', 'c_guest_pwa', 'c_emvco_tlv', '14. Request Dynamic QR', '#D97706')
    add_link('l15', 'c_emvco_tlv', 'c_crc16_engine', '15. Binary Stream', '#D97706')
    add_link('l16', 'c_crc16_engine', 'c_vietqr_renderer', '16. Validated TLV String', '#D97706')
    add_link('l17', 'c_vietqr_renderer', 'c_deeplink_mgr', '17. Render Dynamic QR', '#D97706')
    add_link('l18', 'c_deeplink_mgr', 'c_reconcile_wh', '18. Napas 247 Instant Transfer', '#059669', dashed='1')
    add_link('l19', 'c_reconcile_wh', 'c_ws_gateway', '19. Broadcast `PAID` Event', '#059669')

    tree = ET.ElementTree(mxfile)
    tree.write('projects/splitbill-zero/docs/SplitBill_Zero_Architecture.drawio', encoding='utf-8', xml_declaration=True)
    print("Exported professional Draw.io Enterprise Architecture successfully!")

if __name__ == '__main__':
    build_enterprise_architecture()
