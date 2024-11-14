import sys
import numpy as np

# input variables

in_arr = sys.argv
if '-infile' not in in_arr  not in in_arr:
    print (__doc__)
    raise NameError('error: -infile options are not provided')
elif '-write' not in in_arr:
    print (__doc__)
    raise NameError('error: -write options are not provided')
else:
    ifile = in_arr[in_arr.index('-infile') + 1]
    ofile = in_arr[in_arr.index('-write') + 1]
   
# read 1D files [ tdim x (zdim * 6 mopa)]
slireg = np.loadtxt(ifile)
#slireg = np.loadtxt('epi_slireg.1D')

# define tdim, vardim (=zdim x 6)
dims = np.shape(slireg)
tdim = dims[0]
vardim = dims[1]

# define linear line
dummy = np.linspace(-1, 1, tdim, endpoint=True)


# define the output variable
slireg_zp = slireg

# set zeros for too zero-ish number and demean
for iz in range(0, vardim):
	vec = slireg[:,iz]
	vec = vec - np.mean(vec)
	sumvals = np.sum(np.abs(vec))/tdim
	if ( sumvals < 0.0002 ) :
		nz = int(iz/6)
		mopa = iz - 6*nz 
		print(f'too zero-ish at {nz} slice, {mopa} reg ')
		slireg_zp[:,iz] = dummy
	else :
		slireg_zp[:,iz] = vec

np.savetxt(ofile,slireg_zp)	
print('finished: patch_zeros.py')