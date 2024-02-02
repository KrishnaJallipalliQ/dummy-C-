<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" indent="yes"/>
  
  <xsl:template match="/">
    <html>
      <head>
        <title>PMD Report</title>
        <style>
          body {
            font-family: Arial, sans-serif;
          }
          table {
            border-collapse: collapse;
            width: 100%;
          }
          th, td {
            border: 1px solid #dddddd;
            text-align: left;
            padding: 8px;
          }
          th {
            background-color: #f2f2f2;
          }
        </style>
      </head>
      <body>
        <h1>PMD Report</h1>
        <table>
          <tr>
            <th>File</th>
            <th>Line</th>
            <th>Rule</th>
            <th>Description</th>
          </tr>
          <xsl:apply-templates select="//file"/>
        </table>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="file">
    <tr>
      <td>
        <xsl:value-of select="@name"/>
      </td>
      <td>
        <xsl:value-of select="violation/@beginline"/>
      </td>
      <td>
        <xsl:value-of select="violation/@rule"/>
      </td>
      <td>
        <xsl:value-of select="violation"/>
      </td>
    </tr>
  </xsl:template>

</xsl:stylesheet>
