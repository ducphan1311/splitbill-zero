import subprocess

# Mermaid Flowchart Diagram: Edge OCR Spatial Clustering & Line Matching Algorithm

html_content = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
  body { background: #0B0F19; color: #E2E8F0; padding: 40px; width: 1920px; }
  .header { margin-bottom: 24px; border-bottom: 2px solid #1E293B; padding-bottom: 16px; }
  .tag { font-size: 13px; font-weight: 700; color: #38BDF8; letter-spacing: 2px; text-transform: uppercase; margin-bottom: 6px; }
  .title { font-size: 30px; font-weight: 800; color: #FFFFFF; }
  .title span { color: #38BDF8; }
  .desc { font-size: 14px; color: #94A3B8; margin-top: 4px; }
  .diagram-box { background: #111827; border: 1px solid #1F2937; border-radius: 14px; padding: 28px; }
  .mermaid { display: flex; justify-content: center; }
</style>
<script>
  mermaid.initialize({
    startOnLoad: true,
    theme: 'dark',
    themeVariables: {
      darkMode: true,
      background: '#111827',
      primaryColor: '#1E293B',
      primaryTextColor: '#F8FAFC',
      primaryBorderColor: '#38BDF8',
      lineColor: '#64748B',
      secondaryColor: '#1E293B',
      tertiaryColor: '#0F172A',
      nodeBorder: '#38BDF8',
      clusterBkg: '#0F172A',
      clusterBorder: '#334155',
      mainBkg: '#1E293B'
    }
  });
</script>
</head>
<body>
  <div class="header">
    <div class="tag">Technical Logic Specification</div>
    <div class="title">⚡ SplitBill Zero: <span>Receipt Ingestion & OCR Spatial Clustering Flowchart</span></div>
    <div class="desc">Algorithmic pipeline for converting unstructured 2D receipt image frames into structured Line-Item entities</div>
  </div>
  <div class="diagram-box">
    <div class="mermaid">
flowchart TD
    A([Camera Stream: YUV420 Frame]) --> B[Google ML Kit Text Recognition v2]
    B --> C[Extract TextBlocks, Lines & BoundingBoxes]
    
    subgraph Preprocessing [Spatial & Lexical Preprocessing]
        C --> D[Identify Document Vertical Orientation & Rotation Angle]
        D --> E[Filter Out Noise Elements: Logo, Table No, Address, Date/Time]
    end

    subgraph GeometricMatching [Spatial 2D Geometric Clustering]
        E --> F[Cluster Text Elements by Vertical Band: delta Y &lt;= 0.5 * LineHeight]
        F --> G{Line Contains Numeric Token?}
        G -- Yes --> H[Check Right-Aligned Numeric Token with Currency Formats: k, đ, VND, ., ,]
        G -- No --> I[Candidate Multi-line Dish Name]
        I --> J[Merge with vertically adjacent below text block if aligned left]
        H --> K[Candidate Price Value Entity]
        J --> L[Pair Name Entity with Right-Aligned Price Entity]
        K --> L
    end

    subgraph BusinessValidation [Financial Reconciliation & Tax Distribution]
        L --> M{Is Subtotal / Total / VAT Tag?}
        M -- Yes: Total Tag --> N[Store as Baseline Target Total]
        M -- Yes: VAT/Service Tag --> O[Compute Tax Percentage or Absolute Surcharge]
        M -- No: Standard Dish --> P[Append to LineItems Collection]
        
        N --> Q[Reconcile: Sum of LineItems vs Target Total]
        O --> Q
        P --> Q
        
        Q --> R{Discrepancy Detected?}
        R -- Yes --> S[Flag Line for Host Manual Confirmation / Highlight BoundingBox in Amber]
        R -- No --> T[Validated Receipt JSON Entity]
    end

    S --> U([Render Interactive AR Verification Screen on Mobile Host])
    T --> U
    </div>
  </div>
</body>
</html>
"""

with open("projects/splitbill-zero/docs/flowchart_diagram.html", "w", encoding="utf-8") as f:
    f.write(html_content)

print("Saved flowchart_diagram.html")
