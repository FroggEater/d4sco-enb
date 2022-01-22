from pprint import pprint
import colour
import numpy as np
import sys

try:
  space = sys.argv[1]
except:
  print("Not enough args")
  sys.exit()

np.set_printoptions(formatter={'float': '{:0.15f}'.format}, suppress=True)

if (space == 'h'):
  print(vars(colour.models))
if (space in ['rgb2xyz', 'xyz2rgb']):
  print('> XYZ', colour.models.RGB_COLOURSPACE_BT709.matrix_RGB_to_XYZ)
  print('> RGB', colour.models.RGB_COLOURSPACE_BT709.matrix_XYZ_to_RGB)
if (space in ['ap02xyz', 'xyz2ap0']):
  print('> XYZ', colour.models.RGB_COLOURSPACE_ACES2065_1.matrix_RGB_to_XYZ)
  print('> RGB', colour.models.RGB_COLOURSPACE_ACES2065_1.matrix_XYZ_to_RGB)
if (space in ['ap12xyz', 'xyz2ap1']):
  print('> XYZ', colour.models.RGB_COLOURSPACE_ACESCG.matrix_RGB_to_XYZ)
  print('> RGB', colour.models.RGB_COLOURSPACE_ACESCG.matrix_XYZ_to_RGB)

# print(colour.CHROMATIC_ADAPTATION_METHODS)
# print(colour.CHROMATIC_ADAPTATION_TRANSFORMS)
# print(colour.adaptation.CAT_BRADFORD)