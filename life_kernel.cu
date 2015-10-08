
__global__ void init_kernel(int * domain, int domain_x)
{
	// Dummy initialization
	/*domain[blockIdx.y * domain_x  + blockIdx.x * blockDim.x +  threadIdx.x]
		= (1664525ul * (blockIdx.x + threadIdx.y + threadIdx.x) + 1013904223ul) % 3; */

		int iy = blockDim.y * blockIdx.y + threadIdx.y;
		int ix = blockDim.x * blockIdx.x + threadIdx.x;
		int idx = iy * domain_x + ix;

		domain[idx] = (1664525ul * (blockIdx.x + threadIdx.y + threadIdx.x) + 1013904223ul) % 3;
		__syncthreads();
}

// Reads a cell at (x+dx, y+dy)
__device__ int read_cell(int * source_domain, int x, int y, int dx, int dy,
    unsigned int domain_x, unsigned int domain_y)
{
    x = (unsigned int)(x + dx) % domain_x;	// Wrap around
    y = (unsigned int)(y + dy) % domain_y;
    return source_domain[y * domain_x + x];
}


// Compute kernel
__global__ void life_kernel(int * source_domain, int * dest_domain,
    int domain_x, int domain_y)
{
    int tx = blockIdx.x * blockDim.x + threadIdx.x;
    int ty = blockIdx.y * blockDim.y + threadIdx.y;// computing the y-dimension
    //Shared Memory used by all the threads inside the block
	extern __shared__ int shared_source_domain[];

	for (int i=tx; i<tx+8; i++)
	{
		for (int j=ty; j<ty+8; j++)
		{
			shared_source_domain[i * (domain_x/16) + j] = source_domain[i * domain_x + j];
		}
	}
	__syncthreads();
    // Read cell
    int myself = read_cell(shared_source_domain, tx, ty, 0, 0,
	                       domain_x, domain_y);
    
    // TODO: Read the 8 neighbors and count number of blue and red
	int neighbors=0;
	int red=0, blue=0, blank=0;
	for (int i=-1; i<2; i++)
    {
        for (int j=-1; j<2; j++)
        {
            if ((i !=0) || (j !=0))
            {
                neighbors = read_cell(shared_source_domain, tx, ty, i, j, domain_x, domain_y);

                if (neighbors == 1)
                {
                    red++;
                }
                else if (neighbors == 2)
                {
                    blue++;
                }
				else if (neighbors == 0)
				{
					blank++;
				}
            }
        }
    }
	__syncthreads();
	// TODO: Compute new value

	int all_neighbors = red + blue;
	
	//control flow divergence 
	    
	if ((all_neighbors < 2) || (all_neighbors > 3))
    {
        myself = 0;
    }
    else if ((all_neighbors == 2) || (all_neighbors == 3))
    {
        if ( blue >= 2)
        {
            myself = 2;
        }
        else
        {
            myself = 1;
        }
    }
    __syncthreads();
    // TODO: Write it in dest_domain
    
    dest_domain[(ty * domain_x) + tx] = myself;
}

