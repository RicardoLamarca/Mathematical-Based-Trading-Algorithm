import streamlit as st
import sqlite3
import pandas as pd
import plotly.express as px
import time

# --- PAGE CONFIGURATION ---
st.set_page_config(page_title="Algo Engine | Live Monitor", layout="wide", page_icon="⚡")

# --- HEADER & DESCRIPTION ---
st.title("⚡ Live Execution Dashboard")
st.markdown("Real-time telemetry and execution data streamed directly from the Julia trading core.")

# Database connection
conn = sqlite3.connect('bot_data.sqlite')

try:
    # Load telemetry data
    df_history = pd.read_sql("SELECT * FROM history", conn)
    df_positions = pd.read_sql("SELECT * FROM positions", conn)

    if not df_history.empty:
        # --- CORE METRICS ---
        col1, col2 = st.columns(2)
        current_equity = df_history['equity'].iloc[-1]
        current_cash = df_history['cash'].iloc[-1]
        
        # PRO UPGRADE: Calculate PnL Delta (Current vs Previous tick)
        equity_delta = current_equity - df_history['equity'].iloc[-2] if len(df_history) > 1 else 0.0
        
        col1.metric("Total Equity", f"${current_equity:,.2f}", f"${equity_delta:,.2f}")
        col2.metric("Available Cash", f"${current_cash:,.2f}")

        # --- EQUITY CURVE ---
        st.subheader("📈 Portfolio Equity Curve")
        fig = px.line(df_history, x='timestamp', y='equity', 
                      template="plotly_dark", 
                      line_shape="spline")
        fig.update_traces(line_color='#00FFAA', line_width=3)
        
        # Pro formatting for the chart axes
        fig.update_layout(xaxis_title="Time", yaxis_title="USD ($)", margin=dict(l=0, r=0, t=30, b=0))
        st.plotly_chart(fig, use_container_width=True)

    if not df_positions.empty:
        # --- ACTIVE POSITIONS ---
        st.subheader("💼 Open Positions")
        
        # Pro formatting: Clean up the DataFrame for a better UI presentation
        display_df = df_positions.copy()
        display_df['profit_pct'] = (display_df['profit_pct'] * 100).round(2).astype(str) + '%'
        
        display_df.rename(columns={
            'symbol': 'Ticker', 
            'shares': 'Size', 
            'entry_price': 'Entry Price', 
            'current_price': 'Current Price', 
            'profit_pct': 'Unrealized PnL (%)'
        }, inplace=True)
        
        st.dataframe(display_df, use_container_width=True, hide_index=True)
    else:
        st.info("No active positions in the market right now.")

except sqlite3.OperationalError:
    st.warning("Awaiting telemetry initialization from the Julia trading engine...")
except Exception as e:
    st.error(f"System Error: {e}")

finally:
    conn.close()

# Refresh loop (5 seconds)
time.sleep(5)
st.rerun()
