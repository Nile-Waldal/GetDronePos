import piexif, os, glob, math
from PIL import Image
from fractions import Fraction

#Converts a number to the rational format (int, int) which represents a number
#as (number's numerator, number's denominator)
def num2rat(num):
  #Rounds number to ensure numerator and denominator aren't too large
  x=round(num,7)

  frac=Fraction(str(x))
  return (frac.numerator, frac.denominator)

#Converts angle into a list of rational data types representing whole number
#degrees, whole number arcminutes and decimal arcseconds
def deg2list(t):
  degs=int(math.floor(t))
  mins=int(math.floor((t-degs)*60))
  secs=((t-degs)*60-mins)*60
  secsrat=num2rat(secs)
  return [(degs,1),(mins,1),secsrat]

#Finds current directory
directory=os.getcwd()

#Searches directory for UAV camera corods text file
for file in glob.glob("UAV_camera_coords_*.txt"):
  uav=file

#Opens uav coords and reads lines into a list of strings, with each line being an entry
text=open(uav)
lines=text.readlines()

#Loops through all lines in text file
for strn in lines:

  #Splits line up into image name, northing, easting and elevation
  entries=strn.split(',')
  
  Easting=float(entries[1])
  Northing=float(entries[2])
  elev=float(entries[3])
  Zone=int(entries[4])
  
  #Converts elevation into rational data type, which is a fractional representation
  #of a number in the form (numerator, denominator)
  elevrat=num2rat(elev)
  
  #Sets constants for use in conversion from UTM to GPS
  #Equitorial radius of earth in meters
  a=6378137

  #Flatenning constant of earth
  f=1/298.257222101

  #Third Flatenning constant of earth 
  n=f/(2-f)

  #Circumference of a meridian over 2pi
  A=a/(1+n)*(1+n**2/4+n**4/64+1/256*n**6+25/16384*n**8)

  #Transformation constants
  b1=1/2*n-2/3*n**2+37/96*n**3-1/360*n**4
  b2=1/48*n**2+1/15*n**3-437/1440*n**4
  b3=17/480*n**3-37/840*n**4
  b4=4397/161280*n**4

  #Datum Easting, Northing and point scale factor 
  E0=500000
  N0=0
  k0=0.9996

  #Transformation parameters
  eps=(Northing-N0)/(k0*A)
  nu=(Easting-E0)/(k0*A)
  
  epsp=eps-b1*math.sin(2*eps)*math.cosh(2*nu)-b2*math.sin(4*eps)*math.cosh(4*nu)-b3*math.sin(6*eps)*math.cosh(6*nu)-b4*math.sin(8*eps)*math.cosh(8*nu)
  nup=nu-b1*math.cos(2*eps)*math.sinh(2*nu)-b2*math.cos(4*eps)*math.sinh(4*nu)-b3*math.cos(6*eps)*math.sinh(6*nu)-b4*math.cos(8*eps)*math.sinh(8*nu)
  
  chi=math.asin(math.sin(epsp)/math.cosh(nup))
  
  del1=2*n-2/3*n**2-2*n**3+116/45*n**4
  del2=7/3*n**2-8/5*n**3-227/45*n**4
  del3=56/15*n**3-136/35*n**4
  del4=4279/630*n**4

  #Transformation equations
  long=(chi+del1*math.sin(2*chi)+del2*math.sin(4*chi)+del3*math.sin(6*chi)+del1*math.sin(8*chi))*180/math.pi
  lat=Zone*6-183+180/math.pi*math.atan(math.sinh(nup)/math.cos(epsp))

  #Normalizes coordinates by making all coordinates positive and marking hemispheres
  if lat<0:
    lat=-1*lat
    hemiV="S"
  else:
    hemiV="N"
  if long<0:
    long=-1*long
    hemiH="W"
  else:
    hemiH="E"

  #Splits latitude and longitude into degrees, arcminutes and arcseconds,
  # converts seconds into rational format and puts all parts in a list

  latlist=deg2list(lat)
  longlist=deg2list(long)

  #Loops through directory filenames
  for fname in os.listdir(directory):
    #Executes code if filename matches the entry in the uav camera coords file
    if fname==entries[0]:
      #Opens image
      img = Image.open(fname)

      #Opens exif of image
      exif_dict = piexif.load(fname)

      #Defines updated GPS entry for exif data
      GPS_IFD= {
        piexif.GPSIFD.GPSVersionID: (2, 0, 0, 0),
        piexif.GPSIFD.GPSAltitudeRef: 0,
        piexif.GPSIFD.GPSAltitude: elevrat,
        piexif.GPSIFD.GPSLatitudeRef: hemiV,
        piexif.GPSIFD.GPSLatitude: latlist,
        piexif.GPSIFD.GPSLongitudeRef: hemiH,
        piexif.GPSIFD.GPSLongitude: longlist,
        }

      #Defines the updated GPS entry as a dictionary which can be assumed by
      #the exif of the original image
      gps_exif={"GPS": GPS_IFD}

      #Updates exif of file with the altered GPS entry
      exif_dict.update(gps_exif)

      #Inserts updated exif into file
      exif_bytes=piexif.dump(exif_dict)
      piexif.insert(exif_bytes,fname)

      #Closes image
      img.close

#Close text file
text.close
