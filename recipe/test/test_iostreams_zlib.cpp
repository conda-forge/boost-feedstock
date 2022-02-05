// Ensure that boost::iostreams includes the zlib filter support

#include <fstream>
#include <iostream>
#include <boost/iostreams/filtering_streambuf.hpp>
#include <boost/iostreams/copy.hpp>
#include <boost/iostreams/filter/zlib.hpp>

int main()
{
    using namespace std;

    ifstream file("hello.z", ios_base::in | ios_base::binary);
    boost::iostreams::filtering_streambuf<boost::iostreams::input> in;
    in.push(boost::iostreams::zlib_decompressor());
    in.push(file);
    boost::iostreams::copy(in, cout);
    return 0;
}
