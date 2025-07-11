from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from fastapi.responses import JSONResponse
import uvicorn
import httpx

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/proxy/api/get_list")
async def proxy_get_list(request: Request):
    """
    代理请求到第三方 API，固定参数 ac=list，同时支持其他参数透传
    前端请求示例：/proxy/api/get_list?page=1 → 转发为 ?ac=list&page=1
    """
    try:
        # 组合固定参数和前端传入参数
        base_params = {"ac": "list"}  # 固定参数
        frontend_params = dict(request.query_params)  # 前端传入参数
        merged_params = {**base_params, **frontend_params}  # 合并参数（前端参数优先级更高）

        async with httpx.AsyncClient() as client:
            headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"}
            # 发起代理请求（设置 8 秒超时）
            response = await client.get(
                "https://api.yzzy-api.com/inc/apijson.php",
                params=merged_params,
                headers=headers,
                timeout=8.0
            )
            
            # 如果上游返回非 2xx 状态码，抛出异常
            response.raise_for_status()
            
            # 直接透传 JSON 数据
            return response.json()

    except httpx.HTTPStatusError as e:
        # 捕获第三方 API 返回的错误状态码（如 404, 500 等）
        return JSONResponse(
            status_code=e.response.status_code,
            content={"error": f"上游服务返回错误: {e.response.text}"}
        )
    except httpx.RequestError as e:
        # 处理网络错误（如连接超时、DNS 解析失败等）
        return JSONResponse(
            status_code=503,
            content={"error": f"无法连接第三方服务: {str(e)}"}
        )
    except Exception as e:
        # 处理其他未知异常
        return JSONResponse(
            status_code=500,
            content={"error": f"服务器内部错误: {str(e)}"}
        )
    
@app.get("/proxy/api/get_detail")
async def proxy_get_detail(request: Request):
    """代理详情数据请求"""
    try:
        base_params = {"ac": "detail"}
        frontend_params = dict(request.query_params)
        merged_params = {**base_params, **frontend_params}

        # 推荐方案：使用client.get()
        async with httpx.AsyncClient() as client:
            headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"}
            response = await client.get(
                "https://api.yzzy-api.com/inc/apijson.php",
                params=merged_params,
                headers=headers,
                timeout=8.0  # 正确设置超时位置
            )
            # print("最终请求链接:", response.url)
            # print("返回值:", response.text)
            response.raise_for_status()
            return response.json()

    except httpx.HTTPStatusError as e:
        return JSONResponse(
            status_code=e.response.status_code,
            content={"error": f"上游API错误: {e.response.text}"}
        )
    except httpx.RequestError as e:
        return JSONResponse(
            status_code=503,
            content={"error": f"无法连接数据源: {str(e)}"}
        )
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"error": f"服务器内部错误: {str(e)}"}
        )

# 挂载静态文件
app.mount("/", StaticFiles(directory="dist", html=True), name="static")



# 添加中间件处理SPA路由
@app.middleware("http")
async def spa_middleware(request: Request, call_next):
    response = await call_next(request)
    if response.status_code == 404:
        accept = request.headers.get("accept", "").lower()
        if "text/html" in accept:
            return FileResponse("dist/index.html")
    return response



# API路由
@app.get("/api/hello")
def hello():
    return {"message": "Hello from the API!"}

if __name__ == "__main__":
    uvicorn.run(app, host="localhost", port=80)