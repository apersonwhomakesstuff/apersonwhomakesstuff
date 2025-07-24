local sin, cos, floor, max = math.sin, math.cos, math.floor, math.max

local function main()
    local A, B = 0, 0
    local z = {}
    local b = {}

    term.clear()

    while true do
        for i = 0, 1760 do z[i] = 0.0 end
        for i = 0, 1760 do b[i] = " " end

        for j = 0, 6.28, 0.07 do
            for i = 0, 6.28, 0.07 do
                local sini = sin(i)
                local cosj = cos(j)
                local sinA = sin(A)
                local sinj = sin(j)
                local cosA = cos(A)
                local cosj2 = cosj + 2
                local mess = 1 / (sini * cosj2 * sinA + sinj * cosA + 5)
                local cosi = cos(i)
                local cosB = cos(B)
                local sinB = sin(B)
                local t = sini * cosj2 * cosA - sinj * sinA

                local x = floor(40 + 30 * mess * (cosi * cosj2 * cosB - t * sinB))
                local y = floor(12 + 15 * mess * (cosi * cosj2 * sinB + t * cosB))
                local o = floor(x + 80 * y)
                local N = floor(
                    8 *
                    ((sinj * sinA - sini * cosj * cosA) * cosB - sini * cosj * sinA - sinj * cosA - cosi * cosj * sinB)
                )

                if y < 22 and y > 0 and x > 0 and x < 80 and mess > z[o] then
                    z[o] = mess
                    local n = max(N, 1)
                    b[o] = (".,-~:;=!*#$@"):sub(n, n)
                end
            end
        end

        term.setCursorPos(1, 1)
        local line = ""
        for k = 0, 1760 do
            if k % 80 == 0 and k ~= 0 then
                print(line)
                line = ""
            end
            line = line .. (b[k] or " ")
        end

        A = A + 0.04
        B = B + 0.02
        os.sleep(0.01)
    end
end

main()
