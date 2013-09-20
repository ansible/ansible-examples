# Setup PATH, LD_LIBRARY_PATH and MANPATH for ruby-1.9
ruby19_dir=$(dirname `scl enable ruby193 "which ruby"`)
export PATH=$ruby19_dir:$PATH

ruby19_ld_libs=$(scl enable ruby193 "printenv LD_LIBRARY_PATH")
export LD_LIBRARY_PATH=$ruby19_ld_libs:$LD_LIBRARY_PATH

ruby19_manpath=$(scl enable ruby193 "printenv MANPATH")
export MANPATH=$ruby19_manpath:$MANPATH

