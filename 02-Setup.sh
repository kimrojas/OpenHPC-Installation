yum -y install epel-release
sudo rpm -v --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
sudo rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
sudo yum install exfat-utils fuse-exfat
## Auto tools
yum -y install  ohpc-autotools EasyBuild-ohpc hwloc-ohpc spack-ohpc valgrind-ohpc | tee autotools.o

## Essential modules and software
yum -y install openmpi3-gnu7-ohpc mpich-gnu7-ohpc lmod-defaults-gnu7-openmpi3-ohpc | tee essential_1.o

yum -y install adios-gnu7-openmpi3-ohpc boost-gnu7-openmpi3-ohpc netcdf-gnu7-openmpi3-ohpc \
phdf5-gnu7-openmpi3-ohpc fftw-gnu7-openmpi3-ohpc hypre-gnu7-openmpi3-ohpc imb-gnu7-openmpi3-ohpc \
mfem-gnu7-openmpi3-ohpc  mpiP-gnu7-openmpi3-ohpc  mumps-gnu7-openmpi3-ohpc  netcdf-cxx-gnu7-openmpi3-ohpc \
netcdf-fortran-gnu7-openmpi3-ohpc netcdf-gnu7-openmpi3-ohpc petsc-gnu7-openmpi3-ohpc  pnetcdf-gnu7-openmpi3-ohpc \
scalapack-gnu7-openmpi3-ohpc scalasca-gnu7-openmpi3-ohpc scorep-gnu7-openmpi3-ohpc slepc-gnu7-openmpi3-ohpc \
superlu_dist-gnu7-openmpi3-ohpc tau-gnu7-openmpi3-ohpc trilinos-gnu7-openmpi3-ohpc singularity-ohpc hwloc-ohpc \
pmix-ohpc R-gnu7-ohpc hdf5-gnu7-ohpc mvapich2-gnu7-ohpc plasma-gnu7-ohpc scotch-gnu7-ohpc gnu8-compilers-ohpc  \
openmpi3-gnu8-ohpc  python-mpi4py-gnu7-openmpi3-ohpc  python-mpi4py-gnu8-openmpi3-ohpc  \
python34-mpi4py-gnu7-openmpi3-ohpc python34-mpi4py-gnu8-openmpi3-ohpc mpich-gnu8-ohpc  | tee essential_2.o 
