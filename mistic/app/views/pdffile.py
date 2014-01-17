from pyramid.httpexceptions import HTTPFound, HTTPNotFound, HTTPBadRequest, HTTPInternalServerError
from pyramid.view import view_config
from pyramid.response import Response
from pyramid.renderers import render_to_response

import tempfile
import subprocess
import re
import exceptions

class PDFData(object):
  rsvg_convert = None
  phantomjs = None

  def __init__(self, request):
    self.request = request

  def _convert_rsvg(self, input_file, output_file):
    subprocess.call([self.rsvg_convert, '-f', 'pdf', '-o', output_file, input_file ])

  def _convert_phantomjs(self, input_file, output_file, wd, ht):
    import os.path
    render_script = os.path.join(os.path.dirname(__file__), 'render.js')
    if ht and wd:
      subprocess.call([ self.phantomjs, render_script, input_file, output_file, wd, ht ])
    else:
      subprocess.call([ self.phantomjs, render_script, input_file, output_file ])

  def _convert_svg(self, input_file, output_file, wd, ht):
    subprocess.call([ '/bin/cp', input_file, '/tmp/to_render.svg' ])
    if self.phantomjs is not None:
      return self._convert_phantomjs(input_file, output_file, wd, ht)

    elif self.rsvg_convert is not None:
      return self._convert_rsvg(input_file, output_file)

    raise exceptions.RuntimeError('no svg converter available')

  @view_config(route_name="mistic.pdf.fromsvg", request_method="POST")
  def convert_svg(self):
    _data = self.request.POST['pdfdata']

    from lxml import etree
    import cStringIO
    
    try:
      _data = _data.encode('utf-8', 'ignore')
      doc = etree.parse(cStringIO.StringIO(_data))
    
    except Exception, e: 
      raise HTTPInternalServerError(detail="Unable to generate the requested pdf.  Please contact the administrator")
      
    root = doc.getroot()

    class XPHasClass(object):
      def __init__(self, klass):
        self.klass = klass
      def __repr__(self):
        return "contains(concat(' ', normalize-space(@class), ' '), ' {0} ')".format(self.klass)

    def removeNodes(xpath):
      for node in doc.xpath(xpath, namespaces={'svg':"http://www.w3.org/2000/svg"}):
        node.getparent().remove(node)

    removeNodes('//svg:g[{0}]'.format(XPHasClass('brush')))

    removeNodes('//svg:g[{0}]/svg:text[{1}]'.format(XPHasClass('node'), XPHasClass('invisible')))

    for node in doc.xpath(
        '//svg:g[{0} and {1}]'.format(XPHasClass('node'), XPHasClass('highlighted')),
        namespaces={'svg':"http://www.w3.org/2000/svg"}):
      node.attrib['fill'] = 'rgb(20, 216, 28)'

    # extract width and height
    ht = root.attrib.get('height')
    wd = root.attrib.get('width')

    if ht is None or wd is None:
      ht = wd = None

    input = tempfile.NamedTemporaryFile(suffix='.svg')
    doc.write(input)
    input.flush()

    output = tempfile.NamedTemporaryFile('rb', suffix='.pdf')

    try:
      self._convert_svg(input.name, output.name, wd, ht)
    except:
      raise
      raise HTTPNotFound()

    resp = Response(content_type = 'application/pdf',
                    content_disposition = 'inline;filename=plot.pdf')
    # content_disposition = 'attachment;filename=plot.svg')

    resp.body_file.write(output.read())

    return resp
