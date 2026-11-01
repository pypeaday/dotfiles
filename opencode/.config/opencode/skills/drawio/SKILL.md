---
name: drawio
description: "Create architecture diagrams with draw.io MCP server. Use on 'diagram', 'architecture', 'drawio', 'flowchart', 'visualize'."
---

# draw.io Skill

Create architecture diagrams programmatically using the draw.io MCP server.

**OpenCode note:** Enable the drawio MCP server in the current session before using this skill.

## Prerequisites

1. Start the draw.io container:
   ```bash
   cd ~/dotfiles/ai && docker compose up -d
   ```

2. Verify it's running:
   ```bash
   curl -f http://localhost:8098/
   ```

## MCP Tools

| Tool | Purpose |
|------|---------|
| `start_session` | Opens browser with real-time diagram preview |
| `create_new_diagram` | Create diagram from complete XML |
| `get_diagram` | Get current diagram XML |
| `edit_diagram` | Modify cells by ID (add/update/delete) |
| `export_diagram` | Save as `.drawio` file |

## Workflow

1. Call `start_session` - opens browser preview
2. Call `create_new_diagram` with mxGraphModel XML
3. For edits: call `get_diagram` first, then `edit_diagram`
4. Call `export_diagram` to save file

**CRITICAL:** Must call `get_diagram` within 30 seconds before `edit_diagram` to avoid losing user edits.

## XML Structure

All diagrams use mxGraphModel XML:

```xml
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <!-- Shapes and connections here, parent="1" -->
  </root>
</mxGraphModel>
```

## Basic Shapes

### Rectangle
```xml
<mxCell id="rect1" value="Service" style="rounded=0;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="120" height="60" as="geometry"/>
</mxCell>
```

### Rounded Rectangle
```xml
<mxCell id="rounded1" value="Component" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="120" height="60" as="geometry"/>
</mxCell>
```

### Database/Cylinder
```xml
<mxCell id="db1" value="Database" style="shape=cylinder3;whiteSpace=wrap;html=1;boundedLbl=1;backgroundOutline=1;size=15;fillColor=#f5f5f5;strokeColor=#666666;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="60" height="80" as="geometry"/>
</mxCell>
```

### Cloud Shape
```xml
<mxCell id="cloud1" value="Cloud" style="ellipse;shape=cloud;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="120" height="80" as="geometry"/>
</mxCell>
```

## Connections

### Standard Arrow
```xml
<mxCell id="arrow1" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=classic;" edge="1" parent="1" source="rect1" target="db1">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

### Dashed Arrow
```xml
<mxCell id="arrow2" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;dashed=1;endArrow=classic;" edge="1" parent="1" source="rect1" target="rect2">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

### Bidirectional
```xml
<mxCell id="arrow3" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;startArrow=classic;endArrow=classic;" edge="1" parent="1" source="rect1" target="rect2">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

## AWS Icons

### EC2 Instance
```xml
<mxCell id="ec2" value="EC2" style="sketch=0;outlineConnect=0;fontColor=#232F3E;fillColor=#ED7100;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.ec2;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="78" height="78" as="geometry"/>
</mxCell>
```

### S3 Bucket
```xml
<mxCell id="s3" value="S3" style="sketch=0;outlineConnect=0;fontColor=#232F3E;fillColor=#7AA116;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.s3;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="78" height="78" as="geometry"/>
</mxCell>
```

### Lambda
```xml
<mxCell id="lambda" value="Lambda" style="sketch=0;outlineConnect=0;fontColor=#232F3E;fillColor=#ED7100;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.lambda;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="78" height="78" as="geometry"/>
</mxCell>
```

### RDS Database
```xml
<mxCell id="rds" value="RDS" style="sketch=0;outlineConnect=0;fontColor=#232F3E;fillColor=#C925D1;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.rds;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="78" height="78" as="geometry"/>
</mxCell>
```

### VPC
```xml
<mxCell id="vpc" value="VPC" style="sketch=0;outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_vpc;strokeColor=#879196;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;dashed=0;" vertex="1" parent="1">
  <mxGeometry x="50" y="50" width="400" height="300" as="geometry"/>
</mxCell>
```

### Subnet (Public)
```xml
<mxCell id="subnet-pub" value="Public Subnet" style="sketch=0;outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_security_group;strokeColor=#7AA116;fillColor=#E9F3E6;verticalAlign=top;align=left;spacingLeft=30;dashed=0;" vertex="1" parent="1">
  <mxGeometry x="70" y="80" width="160" height="200" as="geometry"/>
</mxCell>
```

### Subnet (Private)
```xml
<mxCell id="subnet-priv" value="Private Subnet" style="sketch=0;outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_security_group;strokeColor=#147EBA;fillColor=#E6F2F8;verticalAlign=top;align=left;spacingLeft=30;dashed=0;" vertex="1" parent="1">
  <mxGeometry x="250" y="80" width="160" height="200" as="geometry"/>
</mxCell>
```

### EKS Cluster
```xml
<mxCell id="eks" value="EKS" style="sketch=0;outlineConnect=0;fontColor=#232F3E;fillColor=#ED7100;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.eks;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="78" height="78" as="geometry"/>
</mxCell>
```

### ALB/ELB
```xml
<mxCell id="alb" value="ALB" style="sketch=0;outlineConnect=0;fontColor=#232F3E;fillColor=#8C4FFF;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.application_load_balancer;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="78" height="78" as="geometry"/>
</mxCell>
```

## Kubernetes Icons

### Pod
```xml
<mxCell id="pod" value="Pod" style="sketch=0;html=1;dashed=0;whitespace=wrap;fillColor=#2875E2;strokeColor=#ffffff;points=[[0.5,0,0],[1,0.5,0],[0.5,1,0],[0,0.5,0]];verticalLabelPosition=bottom;verticalAlign=top;align=center;shape=mxgraph.kubernetes.icon;prIcon=pod;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="50" height="48" as="geometry"/>
</mxCell>
```

### Deployment
```xml
<mxCell id="deploy" value="Deployment" style="sketch=0;html=1;dashed=0;whitespace=wrap;fillColor=#2875E2;strokeColor=#ffffff;points=[[0.5,0,0],[1,0.5,0],[0.5,1,0],[0,0.5,0]];verticalLabelPosition=bottom;verticalAlign=top;align=center;shape=mxgraph.kubernetes.icon;prIcon=deploy;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="50" height="48" as="geometry"/>
</mxCell>
```

### Service
```xml
<mxCell id="svc" value="Service" style="sketch=0;html=1;dashed=0;whitespace=wrap;fillColor=#2875E2;strokeColor=#ffffff;points=[[0.5,0,0],[1,0.5,0],[0.5,1,0],[0,0.5,0]];verticalLabelPosition=bottom;verticalAlign=top;align=center;shape=mxgraph.kubernetes.icon;prIcon=svc;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="50" height="48" as="geometry"/>
</mxCell>
```

### Ingress
```xml
<mxCell id="ing" value="Ingress" style="sketch=0;html=1;dashed=0;whitespace=wrap;fillColor=#2875E2;strokeColor=#ffffff;points=[[0.5,0,0],[1,0.5,0],[0.5,1,0],[0,0.5,0]];verticalLabelPosition=bottom;verticalAlign=top;align=center;shape=mxgraph.kubernetes.icon;prIcon=ing;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="50" height="48" as="geometry"/>
</mxCell>
```

### ConfigMap
```xml
<mxCell id="cm" value="ConfigMap" style="sketch=0;html=1;dashed=0;whitespace=wrap;fillColor=#2875E2;strokeColor=#ffffff;points=[[0.5,0,0],[1,0.5,0],[0.5,1,0],[0,0.5,0]];verticalLabelPosition=bottom;verticalAlign=top;align=center;shape=mxgraph.kubernetes.icon;prIcon=cm;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="50" height="48" as="geometry"/>
</mxCell>
```

### Secret
```xml
<mxCell id="secret" value="Secret" style="sketch=0;html=1;dashed=0;whitespace=wrap;fillColor=#2875E2;strokeColor=#ffffff;points=[[0.5,0,0],[1,0.5,0],[0.5,1,0],[0,0.5,0]];verticalLabelPosition=bottom;verticalAlign=top;align=center;shape=mxgraph.kubernetes.icon;prIcon=secret;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="50" height="48" as="geometry"/>
</mxCell>
```

### Namespace (Group)
```xml
<mxCell id="ns" value="namespace" style="sketch=0;html=1;dashed=1;whitespace=wrap;fillColor=none;strokeColor=#2875E2;points=[[0.5,0,0],[1,0.5,0],[0.5,1,0],[0,0.5,0]];verticalLabelPosition=top;verticalAlign=bottom;align=center;shape=mxgraph.kubernetes.icon2;kubernetesLabel=1;prIcon=ns;" vertex="1" parent="1">
  <mxGeometry x="50" y="50" width="300" height="200" as="geometry"/>
</mxCell>
```

### PersistentVolume
```xml
<mxCell id="pv" value="PV" style="sketch=0;html=1;dashed=0;whitespace=wrap;fillColor=#2875E2;strokeColor=#ffffff;points=[[0.5,0,0],[1,0.5,0],[0.5,1,0],[0,0.5,0]];verticalLabelPosition=bottom;verticalAlign=top;align=center;shape=mxgraph.kubernetes.icon;prIcon=pv;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="50" height="48" as="geometry"/>
</mxCell>
```

## Layout Guidelines

### Positioning
- Use consistent spacing (e.g., 150px horizontal, 100px vertical)
- Group related components visually
- Place inputs on the left, outputs on the right
- Use containers (VPC, Namespace) to group resources

### Common Layout Pattern
```
x=100: First column (ingress, load balancers)
x=250: Second column (services, APIs)
x=400: Third column (compute, pods)
x=550: Fourth column (data, databases)

y=100: First row
y=200: Second row
y=300: Third row
```

### Colors
- AWS Orange: `#ED7100` (compute)
- AWS Green: `#7AA116` (storage)
- AWS Purple: `#8C4FFF` (networking)
- AWS Pink: `#C925D1` (database)
- K8s Blue: `#2875E2`

## Example: Simple AWS Architecture

```xml
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <mxCell id="alb" value="ALB" style="sketch=0;outlineConnect=0;fontColor=#232F3E;fillColor=#8C4FFF;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.application_load_balancer;" vertex="1" parent="1">
      <mxGeometry x="100" y="150" width="78" height="78" as="geometry"/>
    </mxCell>
    <mxCell id="ec2" value="EC2" style="sketch=0;outlineConnect=0;fontColor=#232F3E;fillColor=#ED7100;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.ec2;" vertex="1" parent="1">
      <mxGeometry x="280" y="150" width="78" height="78" as="geometry"/>
    </mxCell>
    <mxCell id="rds" value="RDS" style="sketch=0;outlineConnect=0;fontColor=#232F3E;fillColor=#C925D1;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.rds;" vertex="1" parent="1">
      <mxGeometry x="460" y="150" width="78" height="78" as="geometry"/>
    </mxCell>
    <mxCell id="arrow1" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=classic;" edge="1" parent="1" source="alb" target="ec2">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
    <mxCell id="arrow2" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=classic;" edge="1" parent="1" source="ec2" target="rds">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
```

## Troubleshooting

### draw.io container not running
```bash
cd ~/dotfiles/ai && docker compose up -d
docker ps | grep drawio
```

### MCP server can't connect
- Verify `http://localhost:8098/` is accessible
- Check `DRAWIO_BASE_URL` is set correctly
- Restart the MCP server

### Diagram not updating
- Browser may need refresh
- Check MCP server logs for errors
```
