package debugging

import "core:fmt"
import "core:mem"

print_unfreed_memory :: proc(tracking_alloc: ^mem.Tracking_Allocator)
{
    alloc_size := len(tracking_alloc.allocation_map)

    if alloc_size > 0
    {
        unfreed_size := tracking_alloc.total_memory_allocated - tracking_alloc.total_memory_freed

        fmt.printfln("{} entries ({}B) unfreed:", alloc_size, unfreed_size)

        for _, entry in tracking_alloc.allocation_map
        {
            fmt.printfln("\t({}) {}", entry.size, entry.location)
        }
    }

    bad_free_size := len(tracking_alloc.bad_free_array)

    if bad_free_size > 0
    {
        fmt.printfln("{} bad frees:", bad_free_size)

        for entry in tracking_alloc.bad_free_array
        {
            fmt.printfln("\t({}) {}", entry.memory, entry.location)
        }
    }
}