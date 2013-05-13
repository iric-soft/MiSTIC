from pyramid.httpexceptions import HTTPFound, HTTPNotFound, HTTPBadRequest
from pyramid.view import view_config
from pyramid.response import Response
from pyramid.renderers import render_to_response

import tempfile
import subprocess
import re

class PDFData(object):
  rsvg_convert = None

  def __init__(self, request):
    self.request = request

  @view_config(route_name="mistic.pdf.fromsvg", request_method="POST")
  def convert_svg(self):
    if self.rsvg_convert is None:
      raise HTTPNotFound()

    _data = self.request.POST['pdfdata']
    _data = re.sub ('<text [^<>]* class="circlelabel invisible">\d*H\d*</text>', '', _data)
   
    
    input = tempfile.NamedTemporaryFile()
    input.write(_data.encode('utf-8'))
    input.flush()

    output = tempfile.NamedTemporaryFile('r')

    subprocess.call([self.rsvg_convert, '-f', 'pdf', '-o', output.name, input.name ])

    resp = Response(content_type = 'application/pdf',
                    content_disposition = 'inline;filename=plot.pdf')
    # content_disposition = 'attachment;filename=plot.svg')

    resp.body_file.write(output.read())

    return resp
